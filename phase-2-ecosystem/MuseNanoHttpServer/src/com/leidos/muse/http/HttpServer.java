/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
package com.leidos.muse.http;

import java.io.IOException;
import java.net.Socket;
import java.util.List;
import java.util.Map;
import java.util.logging.Logger;

import fi.iki.elonen.NanoHTTPD;
import fi.iki.elonen.NanoHTTPD.Response.Status;
import fi.iki.elonen.util.ServerRunner;

/**
 * A custom subclass of NanoHTTPD.
 */
public class HttpServer extends NanoHTTPD {

    /**
     * logger to log to.
     */
    private static final Logger LOG = Logger.getLogger(HttpServer.class.getName());
    
    private String page = "<form method='post' enctype='multipart/form-data'> choose a file<br> <input name='file' type='file' size='50' maxlength='100000'><button type='submit'>upload</button></form>";
    private static int httpServerPort = 8080;
    private static int udpPort = 14550;
    
    private static MavLinkCommunicator mavClient = null;

    public static void main(String[] args) { 
        
        String simulatorHost = "";
        int simPort = 5760;
        
        // assume TCP if 3 arguments supplied (httpServerPort, tcp ip, tcp port)
        if (args.length == 3){
        	
        	// validate httpServer port
        	String sHttpPort = args[0];
        	try{
        		int httpPort = Integer.parseInt(sHttpPort);
        		if(httpPort <= 0 && httpPort >= 65535){
        			throw new NumberFormatException("httpServerPort is out of range: " + sHttpPort);
        		}
        		httpServerPort = httpPort;
        	}catch(NumberFormatException nfe){
        		System.err.println("HTTP Server port not valid: " + sHttpPort);
        		System.err.println("  " + nfe.getMessage());
        		System.exit(1);
        	} 
        	
        	// validate simulator ip
        	simulatorHost = args[1];
        /*	String ipPattern = "(\\d{1,3}\\.\\d{1,3}\\.\\d{1,3}\\.\\d{1,3})";
        	String ipV6Pattern = "\\[([a-zA-Z0-9:]+)\\]:(\\d+)";
        	String hostPattern = "([\\w\\.\\-]+):(\\d+)";  // note will allow _ in host name
        	Pattern p = Pattern.compile( ipPattern + "|" + ipV6Pattern + "|" + hostPattern );
        	Matcher m = p.matcher(simulatorHost);
        	if (!m.matches()) {
        		System.err.println("Simulator IP Address not valid: " + simulatorHost);
        		System.exit(1);
        	}
        	*/
        	// validate simulator port
        	String simulatorPort = args[2];
        	try{
        		simPort = Integer.parseInt(simulatorPort);
        		if(simPort <= 0 && simPort >= 65535){
        			throw new NumberFormatException("simPort is out of range: " + simPort);
        		}
        	}catch(NumberFormatException nfe){
        		System.err.println("Simulator port not valid: " + simulatorPort);
        		System.err.println("  " + nfe.getMessage());
        		System.exit(1);
        	}              	
        	
        	// Try and connect to Simulator
        	System.out.println("Connecting to UAV Simulator on TCP: " + simulatorHost + ":" + simPort);
        	try {
				mavClient = new MavLinkCommunicator(new Socket(simulatorHost, simPort));
				mavClient.start();
			} catch (IOException e) {
				System.err.println(e.getMessage());
				System.err.println("Ensure the Simulator is running and try again.");
				System.exit(1);
			}
        }
        // Defaults to UDP connection if 2 or less arguments are supplied
        else{
        	// Try and connect to Simulator
        	System.out.println("Connecting to UAV Simulator on UDP: " + udpPort);
        	try {
				mavClient = new MavLinkCommunicator(udpPort);
				mavClient.start();
			} catch (Exception e) {
				System.err.println(e.getMessage());
				System.err.println("Ensure the Simulator is running and try again.");
				System.exit(1);
			}
        	
        }
//        else{
//        	System.err.println("Must specify 2 or 3 cmd line args: httpServerPort, simIP and simPort.");
//        	System.err.println("Usage: HttpServer.jar <httpServerPort> <simIP> <simPort>");
//        	System.exit(1);
//        }

    	System.out.println("Simulator connected successfully.");
    	System.out.println();
        
        // Start the HTTP Server
        ServerRunner.run(HttpServer.class);
    }

    public HttpServer() {
        super(httpServerPort);
        System.out.println("MUSE HttpServer starting on port: " + httpServerPort);
    }
    

    @Override
    public Response serve(IHTTPSession session) {
        Method method = session.getMethod();
        String uri = session.getUri();
        HttpServer.LOG.info(method + " '" + uri + "' ");
        session.getHeaders();
        
        String msg = "<html><body><h1>MUSE HTTP server running...</h1>\n</body></html>\n";
        
        if (session.getMethod() == Method.GET) {

	        Map<String, List<String>> parms = session.getParameters();
			
	        // Determine the Mavlink CMD received 
	        List<String> cmd = parms.get("cmd");
	        if (cmd != null) {
	        	System.out.println();
	        	String response = "";

	        	if(cmd.get(0).equals("launch")){
	        		
	        		System.out.println("HttpServer received:  Launch Cmd");
        			if(mavClient != null){
        				response = mavClient.sendLaunchCmd();
        			}
        			return newFixedLengthResponse(Status.OK, NanoHTTPD.MIME_PLAINTEXT, response);
	        	}
	        	else if(cmd.get(0).equals("mode")){
	        		System.out.println("HttpServer received:  Mode Cmd");	        		
        			if(mavClient != null){
        				response = mavClient.sendSetModeCmd(parms.get("mode").get(0));
        			}
        			return newFixedLengthResponse(Status.OK, NanoHTTPD.MIME_PLAINTEXT, response);
	        	}
	        	else if(cmd.get(0).equals("arm")){
	        		System.out.println("HttpServer received:  Arm Cmd");	        		
        			if(mavClient != null){
        				response = mavClient.sendArmCmd();
        			}
        			return newFixedLengthResponse(Status.OK, NanoHTTPD.MIME_PLAINTEXT, response);
	        	}
	        	else if(cmd.get(0).equals("disarm")){
	        		System.out.println("HttpServer received:  Disarm Cmd");	        		
        			if(mavClient != null){
        				response = mavClient.sendDisArmCmd();
        			}
        			return newFixedLengthResponse(Status.OK, NanoHTTPD.MIME_PLAINTEXT, response);
	        	}
	        	else if(cmd.get(0).equals("req")){
	        		System.out.println("HttpServer received:  Mission Request Cmd");
        			if(mavClient != null){
        				response = mavClient.sendReqCmd();
        			}
        			return newFixedLengthResponse(Status.OK, NanoHTTPD.MIME_PLAINTEXT, response);
	        	}
	        	else if(cmd.get(0).equals("land")){
	        		System.out.println("HttpServer received:  Land Cmd");
        			if(mavClient != null){
        				response = mavClient.sendLandCmd();
        			}
        			return newFixedLengthResponse(Status.OK, NanoHTTPD.MIME_PLAINTEXT, response);
	        	}
	        	else if(cmd.get(0).equals("flyto")){
	        		System.out.println("HttpServer received:  FlyTo Cmd");
	        		List<String> waypoints = parms.get("wps");
	        		if (waypoints != null){
	        			System.out.println("Received waypoint pairs: " + waypoints.size());
	        			if(mavClient != null){
	        				response = mavClient.sendFlyToCmd(waypoints);
	        			}
	        		}
        			return newFixedLengthResponse(Status.OK, NanoHTTPD.MIME_PLAINTEXT, response);
	        	}
	        	else{
	        		System.out.println("Unknown MavLink Command Received");
	        	}
	        }
        }
	    return newFixedLengthResponse(msg);
    }
}