package org.bigbluebutton.modules.present.services
{
    import flash.events.Event;
    import flash.events.HTTPStatusEvent;
    import flash.events.IOErrorEvent;
    import flash.events.ProgressEvent;
    import flash.events.SecurityErrorEvent;
    import flash.net.FileReference;
    import flash.net.URLRequest;
    import flash.net.URLRequestMethod;
    import flash.net.URLVariables;
    
    import org.bigbluebutton.core.Logger;
    import org.bigbluebutton.modules.present.events.UploadEvent;
    import org.robotlegs.mvcs.Actor;
    
    public class PresentationUploadService extends Actor
    {
        [Inject]
        public var logger:Logger;
        
        public static const UPLOAD_PROGRESS:String = "UPLOAD_PROGRESS";
        public static const UPLOAD_COMPLETED:String = "UPLOAD_COMPLETED";
        public static const UPLOAD_IO_ERROR:String = "UPLOAD_IO_ERROR";
        public static const UPLOAD_SECURITY_ERROR:String = "UPLOAD_SECURITY_ERROR";
        
        private var request:URLRequest = new URLRequest();
        private var sendVars:URLVariables = new URLVariables();
        
        
        /**
         * Uploads local files to a server 
         * @param file - The FileReference class of the file we wish to send
         * 
         */		
        public function upload(presentationName:String, file:FileReference):void {
//            sendVars.conference = conference;
//            sendVars.room = room;
//            request.url = url;
            request.data = sendVars;
            sendVars.presentation_name = presentationName;
            var fileToUpload : FileReference = new FileReference();
            fileToUpload = file;
            
            fileToUpload.addEventListener(ProgressEvent.PROGRESS, onUploadProgress);
            fileToUpload.addEventListener(Event.COMPLETE, onUploadComplete);
            fileToUpload.addEventListener(IOErrorEvent.IO_ERROR, onUploadIoError);
            fileToUpload.addEventListener(SecurityErrorEvent.SECURITY_ERROR, onUploadSecurityError);
            fileToUpload.addEventListener(HTTPStatusEvent.HTTP_STATUS, httpStatusHandler);
            fileToUpload.addEventListener(Event.OPEN, openHandler);
            
            request.method = URLRequestMethod.POST;
            
            // "fileUpload" is the variable name of the uploaded file in the server
            fileToUpload.upload(request, "fileUpload", true);
        }
        
        private function httpStatusHandler(event:HTTPStatusEvent):void {
            // TO CLEANUP
            //_progressListener(PresentModuleConstants.UPLOAD_IO_ERROR_EVENT, "HTTP STATUS EVENT");
        }
        
        private function openHandler(event:Event):void {
            // TO CLEANUP
            //_progressListener(PresentModuleConstants.UPLOAD_IO_ERROR_EVENT, "OPEN HANDLER");
        }
        
        
        /**
         * Receives an ProgressEvent which then updated the progress bar on the view 
         * @param event - a ProgressEvent
         * 
         */		
        private function onUploadProgress(event:ProgressEvent) : void {
            var percentage:Number = Math.round((event.bytesLoaded / event.bytesTotal) * 100);
            var e:UploadEvent = new UploadEvent(UploadEvent.UPLOAD_PROGRESS_UPDATE);
            e.percentageComplete = percentage;
            dispatch(e);
        }
        
        /**
         * Method is called when the upload has completed successfuly 
         * @param event
         * 
         */		
        private function onUploadComplete(event:Event):void {
            dispatch(new UploadEvent(UploadEvent.UPLOAD_COMPLETE));
        }
        
        /**
         * Receives an ErrorEvent when an error occured during the upload 
         * @param event
         * 
         */
        private function onUploadIoError(event:IOErrorEvent):void {
            logger.error("An error occured while uploading the file. " + event.toString()); 
            dispatch(new UploadEvent(UploadEvent.UPLOAD_IO_ERROR));
           
        }
        
        /**
         * Method is called when a SecurityError is received 
         * @param event
         * 
         */		
        private function onUploadSecurityError(event:SecurityErrorEvent) : void {
            dispatch(new UploadEvent(UploadEvent.UPLOAD_SECURITY_ERROR));
            logger.error("A security error occured while trying to upload the presentation. " + event.toString());
        }
    }
}