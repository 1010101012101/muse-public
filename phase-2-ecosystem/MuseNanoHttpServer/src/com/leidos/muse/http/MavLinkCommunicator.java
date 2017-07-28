/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
package com.leidos.muse.http;

import java.io.DataInputStream;
import java.io.IOException;
import java.io.OutputStream;
import java.net.DatagramPacket;
import java.net.DatagramSocket;
import java.net.Socket;
import java.net.SocketAddress;
import java.net.SocketException;
import java.util.List;

import javax.swing.JFrame;

import org.mavlink.MAVLinkReader;
import org.mavlink.messages.MAVLinkMessage;
import org.mavlink.messages.MAV_CMD;
import org.mavlink.messages.MAV_FRAME;
import org.mavlink.messages.common.msg_attitude;
import org.mavlink.messages.common.msg_command_long;
import org.mavlink.messages.common.msg_heartbeat;
import org.mavlink.messages.common.msg_mission_ack;
import org.mavlink.messages.common.msg_mission_item;
import org.mavlink.messages.common.msg_mission_request;
import org.mavlink.messages.common.msg_set_mode;
import org.mavlink.messages.common.msg_sys_status;
import org.mavlink.messages.common.msg_vfr_hud;

import com.leidos.muse.mapping.DialsVHUD;
import com.sun.speech.freetts.Voice;
import com.sun.speech.freetts.VoiceManager;

/**
 * Simple MAVLink Communicator.  Sends and receives MAVLink commands from
 * our UAV simulator. 
 * @author nathan
 *
 */
class MavLinkCommunicator extends Thread 
{ 
    static final int MAX_SEQUENCE_NUM = 255;
	
    private Socket myClientSocket;
    private  int sequence = 0;
    private boolean m_bRunThread = true; 
    
    // Obtain the input stream and the output stream for the socket  
    private DataInputStream  dis = null; 
    private OutputStream out = null;
    private Thread hbThread = null;
    private MAVLinkReader mavReader = null;
    
    private byte[] ubuffer = new byte[2048];
    private DatagramSocket dsocket = null;
    private DatagramPacket packet = null;
    private SocketAddress address = null;
    private boolean isUDP = false;
    
    private int mySysID = 255;  // system id of our mavlink client
    private int targetID = 1;   //  target id of the simulator 
    
    private boolean bConnected = false;
    private DialsVHUD hud = null;
    private static Voice voice;
    
    private double homeX = 0.0;
    private double homeY = 0.0;
    private double homeZ = 0.0;
    private boolean homeUpdated = false;
    private boolean bManual = false;
 
    
    public MavLinkCommunicator() 
    { 
        super(); 
    } 
    
    /*
     * UDP constructor
     */
    public MavLinkCommunicator(int port) 
    { 
    	try {
    		isUDP = true;
			dsocket = new DatagramSocket(14550);
		    packet = new DatagramPacket(ubuffer, ubuffer.length);
		} catch (SocketException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}
    	
    	System.out.println("Starting GUI");   	
        hud = new DialsVHUD("Leidos Ground Control - HTTP Server");
        hud.pack();
        hud.setVisible(true);
    	
	   	VoiceManager voiceManager = VoiceManager.getInstance();
	   	voice = voiceManager.getVoice("kevin");
    }   

    public MavLinkCommunicator(Socket s) 
    { 
        myClientSocket = s; 
        
        hud = new DialsVHUD("Leidos Ground Control - HTTP Server");
        hud.pack();
        hud.setVisible(true);
        
        VoiceManager voiceManager = VoiceManager.getInstance();
   	  	voice = voiceManager.getVoice("kevin");
    } 
    
    /**
     * Send Mission Request command.  this will ask for the first position of 
     * the copter
     * @return
     */
    public String sendReqCmd(){
    	try {
    		
    		msg_mission_request msg = new msg_mission_request(mySysID, 0);
			msg.sequence = 0;  // 0 denotes 1st position or home position
    		msg.target_system = 1;
    		msg.target_component = 190;
    		
			byte[] result = msg.encode();
			
			System.out.println("Sending Mission Request command... Bytes sent: " + result.length);			
			String response = send(result, false);
			
			try {
				Thread.sleep(1000);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
			if(homeUpdated){
				response = ("Home Position: " + homeX + "; " + homeY + "; " + homeZ);
				homeUpdated = false;
			}
            return response;
			
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		}
    }
    
    public String sendArmCmd(){
    	try {
    		msg_command_long msg = new msg_command_long(mySysID,0);

			msg.command = MAV_CMD.MAV_CMD_COMPONENT_ARM_DISARM;
			msg.sequence = sequence++;
			msg.param1 = 1;
			msg.param2 = 0;
			msg.param3 = 0;
			msg.param4 = 0;
			msg.param5 = 0;
			msg.param6 = 0;
			msg.param7 = 0;
			msg.target_system = targetID;
			msg.target_component = 1;
			msg.confirmation = 0;

			byte[] result1 = msg.encode();
			
			System.out.println("Sending ARM command... Bytes sent: " + result1.length);
			
			String response = send(result1, false);
			speak("armed");
	        
            return response;
    		
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "";
		}
    }
    
    public String sendDisArmCmd(){
    	try {
    		msg_command_long msg = new msg_command_long(mySysID,0);

			msg.command = MAV_CMD.MAV_CMD_COMPONENT_ARM_DISARM;
			msg.sequence = sequence++;
			msg.param1 = 0;
			msg.param2 = 0;
			msg.param3 = 0;
			msg.param4 = 0;
			msg.param5 = 0;
			msg.param6 = 0;
			msg.param7 = 0;
			msg.target_system = targetID;
			msg.target_component = 1;
			msg.confirmation = 0;

			byte[] result1 = msg.encode();
			
			System.out.println("Sending DISARM command... Bytes sent: " + result1.length);
			
			String response = send(result1, false);
			speak("disarmed");
	        
            return response;
    		
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "";
		}
    }
    
    public String sendSetModeCmd(String mode){
    	try {
    		
    		// SET MODE to mode
    		msg_set_mode msg = new msg_set_mode(mySysID,0);
    		msg.sequence = sequence++;
    		msg.target_system = targetID;
    		
    		switch(Integer.valueOf(mode)){
    		case 0:
    			System.out.println("got stabilized mode");
    			speak("mode changed to Stabilized");
    			bManual = true;
        		msg.custom_mode = 0;
        		msg.base_mode = 89;
    			break;
    		case 1:
    			System.out.println("got guided mode");
    			bManual = false;
    			speak("mode changed to guided");
    			msg.custom_mode = 4;
        		msg.base_mode = 59;
    			break;
			case 2:
				System.out.println("got altitude hold mode");
    			speak("mode changed to Altitude Hold");
    			bManual = true;
				msg.custom_mode = 2;
				msg.base_mode = 89;
				break;
			}
    		
    		
    		byte[] result1 = msg.encode();
			
			System.out.println("Sending SET_MODE command... Bytes sent: " + result1.length);
			String response = send(result1, false);
	        
            return response;
    		
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		}
    }
    
    public String sendLaunchCmd(){
    	try {
    		if(!bManual){
    		// SET MODE to GUIDED
    		msg_set_mode msg = new msg_set_mode(mySysID,0);
    		msg.sequence = sequence++;
    		msg.base_mode = 209; 
    		msg.target_system = targetID;
    		msg.custom_mode = 4;
    		
    		byte[] result1 = msg.encode();
			
			System.out.println("Sending SET_MODE Guided command... Bytes sent: " + result1.length);
			send(result1, false);    		
	        
	        try {
				Thread.sleep(100);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
    		}
	        
	        // TAKEOFF Command
            msg_command_long take = new msg_command_long(mySysID,0);
            take.sequence = sequence++;
            take.target_system = 1;
            take.target_component = 1;
            take.command = MAV_CMD.MAV_CMD_NAV_TAKEOFF;
            take.param1 = 0;
            take.param2 = 0;
            take.param3 = 0;
            take.param4 = 0;
            take.param5 = 0;   // lat
            take.param6 = 0;   // lon
            take.param7 = 5;  // altitude in meters
            
			byte[] result2 = take.encode();
			
			System.out.println("Sending TAKEOFF command... Bytes sent: " + result2.length);
			String response = send(result2, false);
	     
			speak("takeoff");
            return response;
    		
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		}
    }
    
    /**
     * Create and send mavlink launch command to UAV simulator.
     * First sets mode to guided then it will send launch
     * @param latitude in degrees
     * @param longitude in decimal degrees
     * @param altitude in meters
     * @return response from simulator
     */
    public String sendLaunchCmd(float latitude, float longitude, float altitude){
        
    	try {
    		// SET MODE to GUIDED
    		msg_set_mode msg = new msg_set_mode(mySysID,0);
    		msg.sequence = sequence++;
    		msg.base_mode = 209; 
    		msg.target_system = targetID;
    		msg.custom_mode = 4;
    		
    		byte[] result1 = msg.encode();
			
			System.out.println("Sending SET_MODE Guided command... Bytes sent: " + result1.length);
			
			send(result1, false);        
	        
	        try {
				Thread.sleep(100);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
	        
	        // TAKEOFF Command
            msg_command_long take = new msg_command_long(mySysID,0);
            take.sequence = sequence++;
            take.target_system = 1;
            take.target_component = 1;
            take.command = MAV_CMD.MAV_CMD_NAV_TAKEOFF;
            take.param1 = 0;
            take.param2 = 0;
            take.param3 = 0;
            take.param4 = 0;
            take.param5 = latitude;   // lat
            take.param6 = longitude;   // lon
            take.param7 = altitude;  // altitude in meters
            
			byte[] result2 = take.encode();
			
			System.out.println("Sending TAKEOFF command... Bytes sent: " + result2.length);
			String response = send(result2, true);
	        
            return response;
            
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		}
    }
    
    
    /**
     * Land UAV
     * @return response from simulator
     */
    public String sendLandCmd(){
    	try {
      
    		// SET MODE to LAND
    		msg_set_mode msg = new msg_set_mode(mySysID,0);
    		msg.sequence = sequence++;
    		msg.base_mode = 217; // what is this?
    		msg.target_system = targetID;
    		msg.custom_mode = 9;
    		
    		byte[] result1 = msg.encode();
			
			System.out.println("Sending SET_MODE command... Bytes sent: " + result1.length);
			send(result1, false);
			speak("land");
	        
	        
	        try {
				Thread.sleep(100);
			} catch (InterruptedException e) {
				// TODO Auto-generated catch block
				e.printStackTrace();
			}
	        
	        // LAND Command
            msg_command_long msgland = new msg_command_long(mySysID,0);
            msgland.sequence = sequence++;
            msgland.target_system = 1;
            msgland.target_component = 1;
            msgland.command = MAV_CMD.MAV_CMD_NAV_LAND;
            msgland.param1 = 0;
            msgland.param2 = 0;
            msgland.param3 = 0;
            msgland.param4 = 0;
            msgland.param5 = 0;
            msgland.param6 = 0;
            msgland.param7 = 00;
            
			byte[] result2 = msgland.encode();
			
			System.out.println("Sending LAND command2... Bytes sent: " + result2.length);
			String response = send(result2, true);
	        
            return response;
	        
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		}
    }
    
    /**
     * Create and send waypoint mission commands to the simulator.  
     * Allows us to tell sim where to fly to.
     * @param waypoint_pairs
     * @return
     */
    public String sendFlyToCmd(List<String> waypoint_pairs){
    	try {
    		if(waypoint_pairs.size() > 0){	
    			// iterate all wp pairs received
    			for(String wp : waypoint_pairs){
	    			Float lat = Float.valueOf(wp.substring(0, wp.indexOf("_")));
	    			Float lon = Float.valueOf(wp.substring(wp.indexOf("_")+1));
	    			Float alt = 10f;
    			
	    			System.out.println("Waypoint received: " + lat + ", " + lon);
	    			
		    		msg_mission_item msg = new msg_mission_item(mySysID, 0);		
					msg.sequence = sequence++;
					msg.seq = 0;
					msg.command = MAV_CMD.MAV_CMD_NAV_WAYPOINT;
					msg.frame = MAV_FRAME.MAV_FRAME_GLOBAL_RELATIVE_ALT;
					msg.current = 2;
					msg.autocontinue = 1;  // autocontinue to next wp
					msg.param1 = 0;
					msg.param2 = 0;
					msg.param3 = 0;
					msg.param4 = 0;
					msg.x = lat;
					msg.y = lon;
					msg.z = alt;
					msg.target_system = targetID;
					msg.target_component = 1;	
					
					byte[] result2 = msg.encode();
					
					System.out.println("Sending FLYTO command... Bytes sent: " + result2.length);
					send(result2, false);
			        		            
			        
			        try {
						Thread.sleep(100);
					} catch (InterruptedException e) {
						// TODO Auto-generated catch block
						e.printStackTrace();
					}
    			}
    		}
    		
	        return "";//waitForResponse(waypoint_pairs.size());
	        
		} catch (NullPointerException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		}
    }
    
    private void speak(String text){     
    	  voice.allocate();
    	  voice.speak(text);
      }
    
    /**
     * Wait for a response from Simulator.  Looking for a command acknowledgement
     * message and will wait upto 2 seconds waiting for this message.
     * @param num - number of cmd acknowledgements expected
     * @return response string from simulator
     */
    private String waitForResponse(int num){
        int waitForResponse = 3000; // 3 secs
        int counter = 0;
        int found = 0;
        String response = "";
        try{
	        // Run in a loop until counter has expired or ack found 
	        while(counter < waitForResponse) 
	        {      
	        	//  At this point, we can read input from simulator.
	            while (dis.available() > 0) {
	            	
	               MAVLinkMessage mavMsg = mavReader.getNextMessage();             
		           if (mavMsg != null) {
		        	   
		        	 // Log any message thats not a heartbeat
		           	 if (mavMsg.messageType != 0 || mavMsg instanceof msg_mission_ack){
		           		 System.out.println("SysId=" + mavMsg.sysId + " CompId=" + mavMsg.componentId + " "+ mavMsg.toString());
		           		 response += (mavMsg.toString() + ",");
		           	 }
		           	 // Received Mavlink CMD acknowledgement or Mission ACK
		             if( mavMsg.messageType == 77 || mavMsg instanceof msg_mission_ack){  
		               	 found++;
		               	 if(found == num){
		           		 counter = 2000;
		               	 }                	 
		             }
		           }
	            }
	            counter += 100;
	        	Thread.sleep(100);
	        }  
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		}
        System.out.println(response);
        return response;
    }
 
    /**
     * Wait for a UDP response from Simulator.  Looking for a command acknowledgement
     * message and will wait upto 2 seconds waiting for this message.
     * @param num - number of cmd acknowledgements expected
     * @return response string from simulator
     */
    private String waitForUDPResponse(int num){
        int waitForResponse = 3000; // 3 secs
        int counter = 0;
        int found = 0;
        String response = "";
        try{
        	while (true) {
        		// Run in a loop until counter has expired or ack found 
        		while(counter < waitForResponse) 
        		{      
	        	//  At this point, we can read input from simulator.
	            
	        	    dsocket.setSoTimeout(2000);
	        	    // Wait to receive a datagram
	        	    dsocket.receive(packet);
	        	    
	               MAVLinkMessage mavMsg = mavReader.getNextMessage(packet.getData(), packet.getLength());           
		           if (mavMsg != null) {
		        	   
		        	 // Log any message thats not a heartbeat
//		           	 if (mavMsg.messageType != 0 || mavMsg instanceof msg_mission_ack){
//		           		 System.out.println("SysId=" + mavMsg.sysId + " CompId=" + mavMsg.componentId + " "+ mavMsg.toString());
//		           		 response += (mavMsg.toString() + ",");
//		           	 }
		           	 // Received Mavlink CMD acknowledgement or Mission ACK
		             if( mavMsg.messageType == 77 || mavMsg instanceof msg_mission_ack){  
		               	 found++;
		               	 if(found == num){
		           		 counter = 2000;
		               	 }                	 
		             }
		             if( mavMsg instanceof msg_mission_item){  
		            	 
		            	 msg_mission_item msg = (msg_mission_item)mavMsg;
		            	 System.out.println("SysId=" + mavMsg.sysId + " CompId=" + mavMsg.componentId + " "+ mavMsg.toString());
		            	 response += ("Home Position: " + msg.x + "; " + msg.y + "; " + msg.z);
		            	 counter = 1600;
		           		 break;         	 
		             }
		           }
		           counter += 100;
		           Thread.sleep(100);
	            }
        		break;
	        }  
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		}
        System.out.println(response);
        return response;
    }
    
    private String waitForPositionResponse(){
        int waitForResponse = 2000; // 3 secs
        int counter = 0;
        int found = 0;
        String response = "";
        try{
	        // Run in a loop until counter has expired or ack found 
	        while(counter < waitForResponse) 
	        {      
	        	//  At this point, we can read input from simulator.
	            while (dis.available() > 0) {
	            	
	               MAVLinkMessage mavMsg = mavReader.getNextMessage();             
		           if (mavMsg != null) {
		        	   
		        	 // Log any message thats not a heartbeat
//		           	 if (mavMsg.messageType != 0 || mavMsg instanceof msg_mission_item){
//		           		 System.out.println("SysId=" + mavMsg.sysId + " CompId=" + mavMsg.componentId + " "+ mavMsg.toString());
//		           		 response += (mavMsg.x + ",");
//		           	 }
		           	 // Received Mavlink CMD Mission item 
		             if( mavMsg instanceof msg_mission_item){  
		            	 
		            	 msg_mission_item msg = (msg_mission_item)mavMsg;
		            	 System.out.println("SysId=" + mavMsg.sysId + " CompId=" + mavMsg.componentId + " "+ mavMsg.toString());
		            	 response += ("Home Position: " + msg.x + "; " + msg.y + "; " + msg.z);
		            	 counter = 1600;
		           		 break;         	 
		             }
		           }
	            }
	            counter += 100;
	        	Thread.sleep(100);
	        }  
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		} catch (InterruptedException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
			return "Error";
		}
        System.out.println(response);
        return response;
    }
    
    /**
     * Send bytes over the wire, either TCP or UDP depending on flag
     * @param results - any output from copter acknowledging
     * @param wait - to wait for results or not (real copter doesnt send acks)
     * @return response acknowledgement from copter
     */
    private String send(byte[] results, boolean wait){
    	String response = "";
    	try{
    		
			if(isUDP){
			    dsocket.send(new DatagramPacket(results, results.length, address));
			    
			    if(wait){
			    	response = waitForUDPResponse(2);
			    }
			    else{
			    	response = "Success";
			    }
			}
			else{
				out.write(results); 
		        out.flush(); 
		        
		        if(wait){
		        	response = waitForResponse(1);
		        }
			    else{
			    	response = "Success";
			    }
			}    	
    	}
	    catch (IOException e) {
		  // TODO Auto-generated catch block
		  e.printStackTrace();
		  return "";
	    }
    	return response;
    }

    public void run() 
    {                  
        try 
        {        
        	//TCP
        	if(!isUDP){
                // Print out details of this connection 
                System.out.println("Accepted Client Address - " + myClientSocket.getInetAddress().getHostName()); 

	            dis = new DataInputStream(myClientSocket.getInputStream());
	            mavReader = new MAVLinkReader(dis);
	            out = myClientSocket.getOutputStream();              
	            // Start Hearbeat 
	            hbThread = new HeartbeatThread(out);
	            hbThread.start();
        	}
        	//UDP
        	else{
        		dsocket.setSoTimeout(1000);
	            mavReader = new MAVLinkReader();
//	            out = myClientSocket.getOutputStream();              
 		
        	}
            
            int nb = 0;          
            // Run in a loop until m_bRunThread is set to false
            while(m_bRunThread) {    
            	// if UDP(real copter), grab socket address then break
            	if(isUDP){
            		dsocket.setSoTimeout(3000);
                	// Wait to receive a datagram
                	dsocket.receive(packet);
                	MAVLinkMessage mavMsg = mavReader.getNextMessage(packet.getData(), packet.getLength());
                	while (mavMsg != null) {
                	    //Grap UDP socket address on 1st message
                		if(address == null){
                		   address = packet.getSocketAddress(); 
                		   if(address != null){
                			   System.out.println("UDP SocketAddress: " + address);
                	    	   
                			   // Start Hearbeat thread
       	       	           	   hbThread = new HeartbeatThread(dsocket);
       	       	           	   hbThread.start();  	       	               
       	       	               	   //break;
                		   }
                	    }
 
                		// MSG ATTITUDE
                		if (mavMsg.messageType == 30 && mavMsg instanceof msg_attitude){               			
                			msg_attitude att = (msg_attitude)mavMsg;
                			hud.updateHUD(att.roll, att.pitch, att.yaw);   	
                		}
                		// VHUD
                		else if (mavMsg.messageType == 74 && mavMsg instanceof msg_vfr_hud){
                			msg_vfr_hud vfr = (msg_vfr_hud)mavMsg;
                			hud.updateHUD2(vfr.heading, vfr.alt, vfr.throttle);
                            System.out.println("	type=" + mavMsg.messageType + " length=" + mavMsg.length + " "+ mavMsg.toString());
                		}
                		else if (mavMsg.messageType == 74 && mavMsg instanceof msg_vfr_hud){
                			msg_vfr_hud att = (msg_vfr_hud)mavMsg;
                			hud.updateHUD2(att.heading, att.alt, att.throttle);   
                		}
                		else if (mavMsg.messageType == 1 && mavMsg instanceof msg_sys_status){
                			msg_sys_status sys = (msg_sys_status)mavMsg;
                			hud.updateHUD3(sys.battery_remaining);   
                		}
                		else if( mavMsg instanceof msg_mission_item){ 
                			msg_mission_item msg = (msg_mission_item)mavMsg;
                            System.out.println("	type=" + mavMsg.messageType + " length=" + mavMsg.length + " "+ mavMsg.toString());
                            homeX = msg.x;
                            homeY = msg.y;
                            homeZ = msg.z;
                            homeUpdated = true;
                		}
                		
                	    if (mavReader.nbUnreadMessages() != 0) {
                	        mavMsg = mavReader.getNextMessageWithoutBlocking();
                	    } else {
                	             break; // Go out of the loop and get new packet
                	    }
      		          // Print out all received messages
                      System.out.println("	SysId=" + mavMsg.sysId + " CompId=" + mavMsg.componentId + " seq=" + mavMsg.sequence + " type=" + mavMsg.messageType + " length=" + mavMsg.length + " "+ mavMsg.toString()); 
                	}      	            
            	}
            	// tcp
//            	else{  
            	 // At this point, we can read for input from simulator.
//                while (dis.available() > 0) {
//                 MAVLinkMessage mavMsg = mavReader.getNextMessage();
//                 
//                 if (mavMsg != null) {
//                     nb++;
//                     if( mavMsg.messageType != 0){
//                    	 bConnected = true;
//                         System.out.println("RCVD TOTAL BYTES = " + mavReader.getTotalBytesReceived());	
//                         System.out.println("	SysId=" + mavMsg.sysId + " CompId=" + mavMsg.componentId + " seq=" + mavMsg.sequence + " type=" + mavMsg.messageType + " length=" + mavMsg.length + " "+ mavMsg.toString());
//                     }
//                 }
//                }
            } 
        } 
        catch(Exception e) 
        { 
            e.printStackTrace(); 
        } 
        finally 
        { 
            // Clean up 
            try 
            {  
            	if(!isUDP){
            		dis.close(); 
            		out.close();
            	}
            	else{
            		dsocket.close();
            	}
                hbThread.stop();
                myClientSocket.close(); 
                System.out.println("...Stopped"); 
            } 
            catch(IOException ioe) 
            { 
                ioe.printStackTrace(); 
            } 
        } 
    } 
    public class HeartbeatThread extends Thread {

    	boolean bStop = false;
    	OutputStream dos = null; ;
    	DatagramSocket dsock = null;
    	
    	public HeartbeatThread(OutputStream os) {
    		this.dos = os;
    	}
    	
    	public HeartbeatThread(DatagramSocket dsocket) {
    		this.dsock = dsocket;
    	}

    	public void stopHeartbeat(){
    		bStop = true;
    	}
    	
    	@Override
    	public void run() {
    		
    		while (!bStop){
    			msg_heartbeat hb = new msg_heartbeat(mySysID,0);
    			
    			// Sequence numbers valid from 0 -255
    			hb.sequence = sequence++;
    			if (hb.sequence > MAX_SEQUENCE_NUM){
    				sequence = 0;
    				hb.sequence = 0;
    			}
    			
    			hb.autopilot = 8;// MAV_AUTOPILOT.MAV_AUTOPILOT_GENERIC;
    			hb.base_mode = 192;// MAV_MODE_FLAG.MAV_MODE_FLAG_GUIDED_ENABLED;
    			hb.custom_mode = 0; //100;
    			hb.mavlink_version = 3;
    			hb.system_status = 4; // MAV_STATE.MAV_STATE_STANDBY;
    			hb.type = 6;
    			
    			byte[] result;
    			try {
    				result = hb.encode();

    				//System.out.println("Sending hearbeat... Bytes sent: " + result.length);
    				if(dos!=null){
    					dos.write(result);
    				}
    				else{
    				    dsocket.send(new DatagramPacket(result, result.length, address));	
    				}
    				
    				Thread.sleep(1000);
    				
    			} catch (IOException e) {
    				// TODO Auto-generated catch block
    				e.printStackTrace();
    			} catch (InterruptedException e) {
    				// TODO Auto-generated catch block
    				e.printStackTrace();
    			}
    		}
    	}
    }
}
