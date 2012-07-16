package org.bigbluebutton.conference;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Iterator;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentLinkedQueue;
import java.util.concurrent.Executor;
import java.util.concurrent.Executors;

import org.red5.server.api.IConnection;
import org.red5.server.api.IScope;
import org.red5.server.api.service.ServiceUtils;

public class ConnectionInvokerService {

	private static final int NTHREADS = 4;
	private static final Executor exec = Executors.newFixedThreadPool(NTHREADS);
			
//	private ConcurrentLinkedQueue<ClientMessage> messages;
	
	private ConcurrentHashMap<String, IConnection> connections;
	private ConcurrentHashMap<String, IScope> scopes;
	
	public ConnectionInvokerService() {
//		messages = new ConcurrentLinkedQueue<ClientMessage>();
		connections = new ConcurrentHashMap<String, IConnection>();
		scopes = new ConcurrentHashMap<String, IScope>();
	}
	
	public void addConnection(String id, IConnection conn) {
		connections.putIfAbsent(id, conn);
	}
	
	public void removeConnection(String id) {
		connections.remove(id);
	}
	
	public void addScope(String id, IScope scope) {
		scopes.putIfAbsent(id, scope);
	}
	
	public void removeScope(String id) {
		scopes.remove(id);
	}
	
	public void sendMessage(final ClientMessage message) {
		Runnable sender = new Runnable() {
			public void run() {
				sendMessageToClient(message);
			}
		};
		exec.execute(sender);
	}
	
	private void sendMessageToClient(ClientMessage message) {
		if (message.getType().equals(ClientMessage.BROADCAST)) {
			IScope scope = scopes.get(message.getDest());
			if (scope != null) {
				List<Object> params = new ArrayList<Object>();
				params.add(message.getMessage());
				ServiceUtils.invokeOnAllConnections(scope, message.getMessageName(), params.toArray());				
			}
		} else if (message.getType().equals(ClientMessage.DIRECT)) {
			IConnection conn = connections.get(message.getDest());
			if (conn != null) {
				if (conn.isConnected()) {
					List<Object> params = new ArrayList<Object>();
					params.add(message.getMessage());
					ServiceUtils.invokeOnConnection(conn, message.getMessageName(), params.toArray());
				}
			}
		}
	}
	
}
