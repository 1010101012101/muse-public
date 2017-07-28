/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
package com.leidos.muse;


import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.GridBagConstraints;
import java.awt.GridBagLayout;
import java.awt.Insets;
import java.awt.event.ActionEvent;
import java.awt.event.ActionListener;
import java.awt.event.MouseAdapter;
import java.awt.event.MouseEvent;
import java.io.BufferedReader;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.StringTokenizer;

import javax.swing.DefaultComboBoxModel;
import javax.swing.DefaultListModel;
import javax.swing.JButton;
import javax.swing.JComboBox;
import javax.swing.JFrame;
import javax.swing.JLabel;
import javax.swing.JList;
import javax.swing.JMenuItem;
import javax.swing.JOptionPane;
import javax.swing.JPanel;
import javax.swing.JPopupMenu;
import javax.swing.JScrollPane;
import javax.swing.JTextArea;
import javax.swing.JTextField;
import javax.swing.ListSelectionModel;
import javax.swing.SwingConstants;
import javax.swing.UIManager;
import javax.swing.border.TitledBorder;
import javax.swing.text.DefaultCaret;
 
/* 
 * ButtonHtmlDemo.java uses the following files:
 *   images/right.gif
 *   images/middle.gif
 *   images/left.gif
 */
public class CmdGeneratorGUI extends JPanel
                             {
	
    public static final String USER_AGENT_FIREFOX = "Mozilla/5.0 (Windows; U; Windows NT 6.0; en-US; rv:1.9.0.10) Gecko/2009042316 Firefox/3.0.10 (.NET CLR 3.5.30729)";
	private JPanel panelLaunch;
	private JButton btnLaunch;
	private JPanel panelWaypoints;
	private JTextField txtf_latitude;
	private JLabel lblLat;
	private JLabel lblLon;
	private JTextField txtf_longitude;
	private JButton btnAddWp;
	private JList lstWaypoints;
	private DefaultListModel<String> listModel = new DefaultListModel<String>();
	private JButton btnLand;
	private JPanel panel_4;
	private JButton btnSendWps;
	private JPanel panel_2;
	private JPanel panel_5;
	private JLabel lblLat_1;
	private JTextField txtfLaunchLat;
	private JLabel lblLon_1;
	private JTextField txtfLaunchLon;
	private JLabel lblAltitude;
	private JTextField txtfLaunchAlt;
	private JPanel panelConsole;
	private JTextArea txtaConsole;
	private JPanel panelServerConfig;
	private JPanel panelModeConfig;
	private JLabel lblIP;
	private JTextField txtfIP;
	private JLabel lblPort;
	private JTextField txtfPort;
	private JButton btnUpdateConfig;
	
	private String host = "127.0.0.1";
	private int port = 8080;
	private JButton btnArm;
	private JLabel lblAlt;
	private JTextField txtfAltitude;
	private JLabel label;
	private JComboBox comboBox;
	private JButton btnUpdate;
	
	private JPopupMenu popup = new JPopupMenu("Menu");
	private JMenuItem btnClear = new JMenuItem("Clear");
	
	private JPopupMenu popupWp = new JPopupMenu("Menu");
	private JMenuItem btnWpClear = new JMenuItem("Clear");
	private JButton btnReq;
	
	private boolean bArmed = false;

 
    public String getHost() {
		return host;
	}

	public void setHost(String host) {
		this.host = host;
	}

	public int getPort() {
		return port;
	}

	public void setPort(int port) {
		this.port = port;
	}

	public CmdGeneratorGUI() {
    	GridBagLayout gridBagLayout = new GridBagLayout();
    	gridBagLayout.columnWidths = new int[] {0};
    	gridBagLayout.rowHeights = new int[] {0};
    	gridBagLayout.columnWeights = new double[]{1.0};
    	gridBagLayout.rowWeights = new double[]{0.0, 0.0, 0.0, 1.0};
    	
    	
    	btnClear.addActionListener(new ActionListener() {
    		public void actionPerformed(ActionEvent arg0) {
    			txtaConsole.setText("");
    		}
    	});
    	popup.add(btnClear);
    	
    	btnWpClear.addActionListener(new ActionListener() {
    		public void actionPerformed(ActionEvent arg0) {
    			listModel.clear();
    		}
    	});
    	popupWp.add(btnWpClear);
    	
    	setLayout(gridBagLayout);
    	
    	panelServerConfig = new JPanel();
    	panelServerConfig.setBorder(new TitledBorder(null, "HTTP Server Configuration", TitledBorder.LEFT, TitledBorder.TOP, null, null));
    	GridBagConstraints gbc_panelServerConfig = new GridBagConstraints();
    	gbc_panelServerConfig.anchor = GridBagConstraints.NORTH;
    	gbc_panelServerConfig.weightx = 1.0;
    	gbc_panelServerConfig.ipady = 10;
    	gbc_panelServerConfig.ipadx = 10;
    	gbc_panelServerConfig.insets = new Insets(5, 5, 5, 5);
    	gbc_panelServerConfig.fill = GridBagConstraints.HORIZONTAL;
    	gbc_panelServerConfig.gridx = 0;
    	gbc_panelServerConfig.gridy = 0;
    	add(panelServerConfig, gbc_panelServerConfig);
    	GridBagLayout gbl_panelServerConfig = new GridBagLayout();
    	gbl_panelServerConfig.columnWidths = new int[] {0};
    	gbl_panelServerConfig.rowHeights = new int[] {0};
    	gbl_panelServerConfig.columnWeights = new double[]{1.0, 1.0, 0.0, 1.0, 0.0};
    	gbl_panelServerConfig.rowWeights = new double[]{0.0};
    	panelServerConfig.setLayout(gbl_panelServerConfig);
    	
    	lblIP = new JLabel("IP");
    	GridBagConstraints gbc_lblIP = new GridBagConstraints();
    	gbc_lblIP.anchor = GridBagConstraints.EAST;
    	gbc_lblIP.insets = new Insets(5, 10, 5, 10);
    	gbc_lblIP.gridx = 0;
    	gbc_lblIP.gridy = 0;
    	panelServerConfig.add(lblIP, gbc_lblIP);
    	
    	txtfIP = new JTextField();
    	GridBagConstraints gbc_txtfIP = new GridBagConstraints();
    	gbc_txtfIP.fill = GridBagConstraints.HORIZONTAL;
    	gbc_txtfIP.anchor = GridBagConstraints.WEST;
    	gbc_txtfIP.insets = new Insets(5, 5, 5, 5);
    	gbc_txtfIP.gridx = 1;
    	gbc_txtfIP.gridy = 0;
    	panelServerConfig.add(txtfIP, gbc_txtfIP);
    	txtfIP.setColumns(10);
    	txtfIP.setText("127.0.0.1");
    	
    	lblPort = new JLabel("Port");
    	GridBagConstraints gbc_lblPort = new GridBagConstraints();
    	gbc_lblPort.anchor = GridBagConstraints.EAST;
    	gbc_lblPort.insets = new Insets(5, 10, 5, 10);
    	gbc_lblPort.gridx = 2;
    	gbc_lblPort.gridy = 0;
    	panelServerConfig.add(lblPort, gbc_lblPort);
    	
    	txtfPort = new JTextField();
    	GridBagConstraints gbc_txtfPort = new GridBagConstraints();
    	gbc_txtfPort.insets = new Insets(5, 5, 5, 5);
    	gbc_txtfPort.anchor = GridBagConstraints.WEST;
    	gbc_txtfPort.fill = GridBagConstraints.HORIZONTAL;
    	gbc_txtfPort.gridx = 3;
    	gbc_txtfPort.gridy = 0;
    	panelServerConfig.add(txtfPort, gbc_txtfPort);
    	txtfPort.setColumns(10);
    	txtfPort.setText("8080");
    	
    	btnUpdateConfig = new JButton("Update");
    	GridBagConstraints gbc_btnUpdateConfig = new GridBagConstraints();
    	gbc_btnUpdateConfig.insets = new Insets(5, 5, 5, 5);
    	gbc_btnUpdateConfig.gridx = 4;
    	gbc_btnUpdateConfig.gridy = 0;
    	panelServerConfig.add(btnUpdateConfig, gbc_btnUpdateConfig);
   
    	panelModeConfig = new JPanel();
    	panelModeConfig.setBorder(new TitledBorder(null, "Mode", TitledBorder.LEFT, TitledBorder.TOP, null, null));
    	GridBagConstraints gbc_panelMode = new GridBagConstraints();
    	gbc_panelMode.anchor = GridBagConstraints.NORTH;
    	gbc_panelMode.weightx = 1.0;
    	gbc_panelMode.ipady = 10;
    	gbc_panelMode.ipadx = 10;
    	gbc_panelMode.insets = new Insets(5, 5, 5, 5);
    	gbc_panelMode.fill = GridBagConstraints.HORIZONTAL;
    	gbc_panelMode.gridx = 0;
    	gbc_panelMode.gridy = 1;
    	add(panelModeConfig, gbc_panelMode);
    	GridBagLayout gbl_panelMode = new GridBagLayout();
    	gbl_panelMode.columnWidths = new int[] {0, 0, 0};
    	gbl_panelMode.rowHeights = new int[] {0, 0};
    	gbl_panelMode.columnWeights = new double[]{1.0, 0.0, 0.0};
    	gbl_panelMode.rowWeights = new double[]{0.0, 0.0};
    	panelModeConfig.setLayout(gbl_panelMode);
    	
    	comboBox = new JComboBox();
    	comboBox.setFont(new Font("Verdana", Font.BOLD, 13));
    	comboBox.setBackground(Color.WHITE);
    	comboBox.setModel(new DefaultComboBoxModel(new String[] {"Stablized", "Guided", "Alt Hold", "Land"}));
    	GridBagConstraints gbc_comboBox = new GridBagConstraints();
    	gbc_comboBox.fill = GridBagConstraints.HORIZONTAL;
    	gbc_comboBox.insets = new Insets(5, 15, 5, 5);
    	gbc_comboBox.gridx = 0;
    	gbc_comboBox.gridy = 0;
    	panelModeConfig.add(comboBox, gbc_comboBox);
    	
    	btnUpdate = new JButton("Update");
    	btnUpdate.addActionListener(new ActionListener() {
    		public void actionPerformed(ActionEvent e) {
    	        Map<String,String> params = new LinkedHashMap<>();
    	        params.put("cmd", "mode");
    	        params.put("mode", String.valueOf(comboBox.getSelectedIndex()));
    	        
    	        sendHttpRequest(params);
    		}
    	});
    	GridBagConstraints gbc_btnUpdate = new GridBagConstraints();
    	gbc_btnUpdate.insets = new Insets(0, 0, 5, 0);
    	gbc_btnUpdate.gridx = 2;
    	gbc_btnUpdate.gridy = 0;
    	panelModeConfig.add(btnUpdate, gbc_btnUpdate);
    	
    	label = new JLabel("");
    	GridBagConstraints gbc_label = new GridBagConstraints();
    	gbc_label.insets = new Insets(0, 0, 0, 5);
    	gbc_label.gridx = 1;
    	gbc_label.gridy = 1;
    	panelModeConfig.add(label, gbc_label);
    	
    	panelLaunch = new JPanel();
    	panelLaunch.setBorder(new TitledBorder(UIManager.getBorder("TitledBorder.border"), "Nav Commands", TitledBorder.LEFT, TitledBorder.TOP, null, new Color(0, 0, 0)));
    	GridBagConstraints gbc_panelLaunch = new GridBagConstraints();
    	gbc_panelLaunch.ipady = 10;
    	gbc_panelLaunch.ipadx = 10;
    	gbc_panelLaunch.anchor = GridBagConstraints.NORTH;
    	gbc_panelLaunch.weightx = 1.0;
    	gbc_panelLaunch.insets = new Insets(5, 5, 5, 5);
    	gbc_panelLaunch.fill = GridBagConstraints.HORIZONTAL;
    	gbc_panelLaunch.gridx = 0;
    	gbc_panelLaunch.gridy = 2;
    	add(panelLaunch, gbc_panelLaunch);
    	GridBagLayout gbl_panelLaunch = new GridBagLayout();
    	gbl_panelLaunch.columnWidths = new int[] {0};
    	gbl_panelLaunch.rowHeights = new int[] {0};
    	gbl_panelLaunch.columnWeights = new double[]{1.0};
    	gbl_panelLaunch.rowWeights = new double[]{1.0, 1.0};
    	panelLaunch.setLayout(gbl_panelLaunch);
    	
    	panel_2 = new JPanel();
    	panel_2.setBorder(new TitledBorder(UIManager.getBorder("TitledBorder.border"), "optional", TitledBorder.CENTER, TitledBorder.TOP, null, null));
    	GridBagConstraints gbc_panel_2 = new GridBagConstraints();
    	gbc_panel_2.weightx = 1.0;
    	gbc_panel_2.insets = new Insets(5, 5, 5, 5);
    	gbc_panel_2.fill = GridBagConstraints.HORIZONTAL;
    	gbc_panel_2.gridx = 0;
    	gbc_panel_2.gridy = 0;
    	panelLaunch.add(panel_2, gbc_panel_2);
    	GridBagLayout gbl_panel_2 = new GridBagLayout();
    	gbl_panel_2.columnWidths = new int[]{0, 0, 0, 0, 0, 0, 0};
    	gbl_panel_2.rowHeights = new int[]{0, 0};
    	gbl_panel_2.columnWeights = new double[]{0.0, 0.0, 0.0, 0.0, 0.0, 1.0, Double.MIN_VALUE};
    	gbl_panel_2.rowWeights = new double[]{0.0, Double.MIN_VALUE};
    	panel_2.setLayout(gbl_panel_2);
    	
    	lblLat_1 = new JLabel("Lat");
    	GridBagConstraints gbc_lblLat_1 = new GridBagConstraints();
    	gbc_lblLat_1.insets = new Insets(3, 3, 3, 2);
    	gbc_lblLat_1.anchor = GridBagConstraints.EAST;
    	gbc_lblLat_1.gridx = 0;
    	gbc_lblLat_1.gridy = 0;
    	panel_2.add(lblLat_1, gbc_lblLat_1);
    	
    	txtfLaunchLat = new JTextField();
    	GridBagConstraints gbc_txtfLaunchLat = new GridBagConstraints();
    	gbc_txtfLaunchLat.weightx = 1.0;
    	gbc_txtfLaunchLat.insets = new Insets(3, 3, 3, 3);
    	gbc_txtfLaunchLat.fill = GridBagConstraints.HORIZONTAL;
    	gbc_txtfLaunchLat.gridx = 1;
    	gbc_txtfLaunchLat.gridy = 0;
    	panel_2.add(txtfLaunchLat, gbc_txtfLaunchLat);
    	txtfLaunchLat.setColumns(10);
    	
    	lblLon_1 = new JLabel("Lon");
    	GridBagConstraints gbc_lblLon_1 = new GridBagConstraints();
    	gbc_lblLon_1.insets = new Insets(3, 3, 3, 2);
    	gbc_lblLon_1.anchor = GridBagConstraints.EAST;
    	gbc_lblLon_1.gridx = 2;
    	gbc_lblLon_1.gridy = 0;
    	panel_2.add(lblLon_1, gbc_lblLon_1);
    	
    	txtfLaunchLon = new JTextField();
    	GridBagConstraints gbc_txtfLaunchLon = new GridBagConstraints();
    	gbc_txtfLaunchLon.weightx = 1.0;
    	gbc_txtfLaunchLon.insets = new Insets(3, 3, 3, 3);
    	gbc_txtfLaunchLon.fill = GridBagConstraints.HORIZONTAL;
    	gbc_txtfLaunchLon.gridx = 3;
    	gbc_txtfLaunchLon.gridy = 0;
    	panel_2.add(txtfLaunchLon, gbc_txtfLaunchLon);
    	txtfLaunchLon.setColumns(10);
    	
    	lblAltitude = new JLabel("Altitude");
    	GridBagConstraints gbc_lblAltitude = new GridBagConstraints();
    	gbc_lblAltitude.anchor = GridBagConstraints.EAST;
    	gbc_lblAltitude.insets = new Insets(3, 3, 3, 2);
    	gbc_lblAltitude.gridx = 4;
    	gbc_lblAltitude.gridy = 0;
    	panel_2.add(lblAltitude, gbc_lblAltitude);
    	
    	txtfLaunchAlt = new JTextField();
    	GridBagConstraints gbc_txtfLaunchAlt = new GridBagConstraints();
    	gbc_txtfLaunchAlt.fill = GridBagConstraints.HORIZONTAL;
    	gbc_txtfLaunchAlt.gridx = 5;
    	gbc_txtfLaunchAlt.gridy = 0;
    	panel_2.add(txtfLaunchAlt, gbc_txtfLaunchAlt);
    	txtfLaunchAlt.setColumns(10);
    	
    	panel_5 = new JPanel();
    	GridBagConstraints gbc_panel_5 = new GridBagConstraints();
    	gbc_panel_5.insets = new Insets(0, 0, 0, 5);
    	gbc_panel_5.fill = GridBagConstraints.BOTH;
    	gbc_panel_5.gridx = 0;
    	gbc_panel_5.gridy = 1;
    	panelLaunch.add(panel_5, gbc_panel_5);
    	
    	btnArm = new JButton("Arm");
    	btnArm.addActionListener(new ActionListener() {
    		public void actionPerformed(ActionEvent arg0) {
    	        Map<String,String> params = new LinkedHashMap<>();
    	        if(!bArmed){
    	        	btnArm.setText("Disarm");
    	        	params.put("cmd", "arm");
    	        	bArmed = true;
    	        }
    	        else{
    	        	btnArm.setText("Arm");
    	        	params.put("cmd", "disarm");
    	        	bArmed = false;
    	        }
    	        
    	        sendHttpRequest(params);
    	        
    	        btnLaunch.setEnabled(true);
    			
    		}
    	});
    	
    	btnReq = new JButton("GetPosition");
    	btnReq.setFont(new Font("Tahoma", Font.BOLD, 13));
    	btnReq.setHorizontalAlignment(SwingConstants.LEFT);
    	btnReq.addActionListener(new ActionListener() {
    		public void actionPerformed(ActionEvent arg0) {
    	        Map<String,String> params = new LinkedHashMap<>();
    	        params.put("cmd", "req");
    	        
    	        sendHttpRequest(params);
    	        
    	        //btnLaunch.setEnabled(true);
    			
    		}
    	});
    	
    	
    	panel_5.add(btnReq);
    	btnArm.setFont(new Font("Tahoma", Font.BOLD, 15));
    	panel_5.add(btnArm);
    	
    	btnLaunch = new JButton("Launch");
    	btnLaunch.setEnabled(false);
    	panel_5.add(btnLaunch);
    	btnLaunch.setFont(new Font("Tahoma", Font.BOLD, 15));
    	
    	btnLand = new JButton("Land");
    	btnLand.setEnabled(false);
    	panel_5.add(btnLand);
    	btnLaunch.addActionListener(new ActionListener() {
    		public void actionPerformed(ActionEvent arg0) {

    	        Map<String,String> params = new LinkedHashMap<>();
    	        params.put("cmd", "launch");
    	        
    	        //check for optional parameters
    	        if(!txtfLaunchLat.getText().isEmpty()){
    	        	params.put("lat", txtfLaunchLat.getText());
    	        }
    	        if(!txtfLaunchLon.getText().isEmpty()){
    	        	params.put("lon", txtfLaunchLon.getText());
    	        }
    	        if(!txtfLaunchAlt.getText().isEmpty()){
    	        	params.put("alt", txtfLaunchAlt.getText());
    	        }
    	        
    	        sendHttpRequest(params);
    	        
    	        btnLand.setEnabled(true); 
    	        comboBox.setSelectedIndex(1);
    		}
    	});
    	
    	btnLand.addActionListener(new ActionListener() {
    		public void actionPerformed(ActionEvent arg0) {
    	        Map<String,String> params = new LinkedHashMap<>();
    	        params.put("cmd", "land");

    	        sendHttpRequest(params);
    		}
    	});
    	btnLand.setFont(new Font("Tahoma", Font.BOLD, 15));

    	
    	panelWaypoints = new JPanel();
    	panelWaypoints.setBorder(new TitledBorder(UIManager.getBorder("TitledBorder.border"), "Send Waypoints", TitledBorder.LEFT, TitledBorder.TOP, null, new Color(0, 0, 0)));
    	GridBagConstraints gbc_panelWaypoints = new GridBagConstraints();
    	gbc_panelWaypoints.ipadx = 10;
    	gbc_panelWaypoints.ipady = 10;
    	gbc_panelWaypoints.weighty = 1.0;
    	gbc_panelWaypoints.weightx = 1.0;
    	gbc_panelWaypoints.insets = new Insets(5, 5, 5, 5);
    	gbc_panelWaypoints.fill = GridBagConstraints.BOTH;
    	gbc_panelWaypoints.gridx = 0;
    	gbc_panelWaypoints.gridy = 3;
    	add(panelWaypoints, gbc_panelWaypoints);
    	GridBagLayout gbl_panelWaypoints = new GridBagLayout();
    	gbl_panelWaypoints.columnWidths = new int[] {0, 0, 0, 0, 0, 0};
    	gbl_panelWaypoints.rowHeights = new int[] {0};
    	gbl_panelWaypoints.columnWeights = new double[]{1.0, 1.0, 0.0, 1.0, 0.0, 1.0, 0.0};
    	gbl_panelWaypoints.rowWeights = new double[]{0.0, 1.0, 1.0, 0.0, 0.0};
    	panelWaypoints.setLayout(gbl_panelWaypoints);
    	
    	lblLat = new JLabel("Lat");
    	lblLat.setHorizontalAlignment(SwingConstants.LEFT);
    	GridBagConstraints gbc_lblLat = new GridBagConstraints();
    	gbc_lblLat.insets = new Insets(5, 5, 5, 5);
    	gbc_lblLat.gridx = 0;
    	gbc_lblLat.gridy = 0;
    	panelWaypoints.add(lblLat, gbc_lblLat);
    	
    	txtf_latitude = new JTextField();
    	txtf_latitude.setHorizontalAlignment(SwingConstants.CENTER);
    	GridBagConstraints gbc_txtf_latitude = new GridBagConstraints();
    	gbc_txtf_latitude.weightx = 1.0;
    	gbc_txtf_latitude.fill = GridBagConstraints.HORIZONTAL;
    	gbc_txtf_latitude.insets = new Insets(5, 5, 5, 5);
    	gbc_txtf_latitude.gridx = 1;
    	gbc_txtf_latitude.gridy = 0;
    	panelWaypoints.add(txtf_latitude, gbc_txtf_latitude);
    	txtf_latitude.setColumns(10);
    	
    	lblLon = new JLabel("Lon");
    	GridBagConstraints gbc_lblLon = new GridBagConstraints();
    	gbc_lblLon.anchor = GridBagConstraints.EAST;
    	gbc_lblLon.insets = new Insets(5, 5, 5, 5);
    	gbc_lblLon.gridx = 2;
    	gbc_lblLon.gridy = 0;
    	panelWaypoints.add(lblLon, gbc_lblLon);
    	
    	txtf_longitude = new JTextField();
    	txtf_longitude.setHorizontalAlignment(SwingConstants.CENTER);
    	GridBagConstraints gbc_txtf_longitude = new GridBagConstraints();
    	gbc_txtf_longitude.weightx = 1.0;
    	gbc_txtf_longitude.fill = GridBagConstraints.HORIZONTAL;
    	gbc_txtf_longitude.insets = new Insets(5, 5, 5, 5);
    	gbc_txtf_longitude.gridx = 3;
    	gbc_txtf_longitude.gridy = 0;
    	panelWaypoints.add(txtf_longitude, gbc_txtf_longitude);
    	txtf_longitude.setColumns(10);
    	
    	lblAlt = new JLabel("Alt");
    	GridBagConstraints gbc_lblAlt = new GridBagConstraints();
    	gbc_lblAlt.anchor = GridBagConstraints.EAST;
    	gbc_lblAlt.insets = new Insets(5, 5, 5, 5);
    	gbc_lblAlt.gridx = 4;
    	gbc_lblAlt.gridy = 0;
    	panelWaypoints.add(lblAlt, gbc_lblAlt);
    	
    	txtfAltitude = new JTextField();
    	GridBagConstraints gbc_txtfAltitude = new GridBagConstraints();
    	gbc_txtfAltitude.weightx = 1.0;
    	gbc_txtfAltitude.insets = new Insets(5, 5, 5, 5);
    	gbc_txtfAltitude.fill = GridBagConstraints.HORIZONTAL;
    	gbc_txtfAltitude.gridx = 5;
    	gbc_txtfAltitude.gridy = 0;
    	panelWaypoints.add(txtfAltitude, gbc_txtfAltitude);
    	txtfAltitude.setColumns(10);
    	
    	lstWaypoints = new JList<String>(listModel);
    	lstWaypoints.addMouseListener(new MouseAdapter() {
    		@Override
    		public void mouseClicked(MouseEvent e) {
    			popupWp.show(lstWaypoints,e.getX(),e.getY());
    		}
    	});

    	lstWaypoints.setVisibleRowCount(22);
    	lstWaypoints.setSelectionMode(ListSelectionModel.SINGLE_SELECTION);
    	lstWaypoints.setBorder(new TitledBorder(null, "Waypoint List", TitledBorder.LEADING, TitledBorder.TOP, null, null));
    	GridBagConstraints gbc_lstWaypoints = new GridBagConstraints();
    	gbc_lstWaypoints.weighty = 1.0;
    	gbc_lstWaypoints.weightx = 1.0;
    	gbc_lstWaypoints.insets = new Insets(5, 5, 5, 0);
    	gbc_lstWaypoints.gridwidth = 7;
    	gbc_lstWaypoints.gridheight = 4;
    	gbc_lstWaypoints.fill = GridBagConstraints.BOTH;
    	gbc_lstWaypoints.gridx = 0;
    	gbc_lstWaypoints.gridy = 1;
    	panelWaypoints.setPreferredSize(new Dimension(400,200));
    	
    	btnAddWp = new JButton("Add");
    	btnAddWp.addActionListener(new ActionListener() {
    		public void actionPerformed(ActionEvent arg0) {
    			if(txtf_latitude.getText() != "" && txtf_longitude.getText() != "" ){
    				try{
    				   double lat = Double.parseDouble(txtf_latitude.getText());
    				   double lon = Double.parseDouble(txtf_longitude.getText());
    				   double alt = Double.parseDouble(txtfAltitude.getText());
    				   listModel.addElement(String.valueOf(lat) + "," + String.valueOf(lon) + "," + String.valueOf(alt));
    				   btnSendWps.setEnabled(true);
    				}
    				catch(NumberFormatException nfe){
    				   System.err.println("Not valid lat or lon values.");
    				   JOptionPane.showMessageDialog(txtf_latitude.getParent(), "Not valid lat/long value: " + txtf_latitude.getText() + "," + txtf_longitude.getText(), "Invalid Number", JOptionPane.ERROR_MESSAGE);
    				}
    			}
    		}
    	});
    	GridBagConstraints gbc_btnAddWp = new GridBagConstraints();
    	gbc_btnAddWp.insets = new Insets(5, 5, 5, 5);
    	gbc_btnAddWp.gridx = 6;
    	gbc_btnAddWp.gridy = 0;
    	panelWaypoints.add(btnAddWp, gbc_btnAddWp);
    	panelWaypoints.add(lstWaypoints, gbc_lstWaypoints);
    	
    	panel_4 = new JPanel();
    	GridBagConstraints gbc_panel_4 = new GridBagConstraints();
    	gbc_panel_4.gridwidth = 7;
    	gbc_panel_4.weightx = 1.0;
    	gbc_panel_4.insets = new Insets(5, 5, 0, 0);
    	gbc_panel_4.fill = GridBagConstraints.HORIZONTAL;
    	gbc_panel_4.gridx = 0;
    	gbc_panel_4.gridy = 5;
    	panelWaypoints.add(panel_4, gbc_panel_4);
    	GridBagLayout gbl_panel_4 = new GridBagLayout();
    	gbl_panel_4.columnWidths = new int[] {0};
    	gbl_panel_4.rowHeights = new int[] {0};
    	gbl_panel_4.columnWeights = new double[]{0.0};
    	gbl_panel_4.rowWeights = new double[]{0.0};
    	panel_4.setLayout(gbl_panel_4);
    	
    	btnSendWps = new JButton("Send WPs");
    	btnSendWps.addActionListener(new ActionListener() {
    		public void actionPerformed(ActionEvent e) {
    	        StringBuilder wpParams = new StringBuilder();
    	        wpParams.append("cmd=flyto&");
    	        
    	        int i = 0;
    	        for(Object wp : listModel.toArray()){
    	        	if (i!=0){
    	        		wpParams.append("&");
    	        	}
    	        		wpParams.append("wps=" + ((String)wp).replace(',', '_'));
    	        	i++;
    	        }
    	        sendHttpWPRequest(wpParams);
    		}
    	});
    	btnSendWps.setEnabled(false);
    	btnSendWps.setFont(new Font("Tahoma", Font.BOLD, 15));
    	GridBagConstraints gbc_btnSendWps = new GridBagConstraints();
    	gbc_btnSendWps.fill = GridBagConstraints.HORIZONTAL;
    	gbc_btnSendWps.gridx = 0;
    	gbc_btnSendWps.gridy = 0;
    	panel_4.add(btnSendWps, gbc_btnSendWps);
    	

    	
    	panelConsole = new JPanel();
    	panelConsole.setBorder(new TitledBorder(null, "Console", TitledBorder.LEFT, TitledBorder.TOP, null, null));
    	GridBagConstraints gbc_panelConsole = new GridBagConstraints();
    	gbc_panelConsole.ipadx = 10;
    	gbc_panelConsole.ipady = 10;
    	gbc_panelConsole.insets = new Insets(5, 5, 5, 5);
    	gbc_panelConsole.weighty = 1.0;
    	gbc_panelConsole.weightx = 1.0;
    	gbc_panelConsole.fill = GridBagConstraints.BOTH;
    	gbc_panelConsole.gridx = 0;
    	gbc_panelConsole.gridy = 4;  	
    	GridBagLayout gbl_panelConsole = new GridBagLayout();
    	gbl_panelConsole.columnWidths = new int[] {0};
    	gbl_panelConsole.rowHeights = new int[] {0};
    	gbl_panelConsole.columnWeights = new double[]{1.0};
    	gbl_panelConsole.rowWeights = new double[]{1.0};
    	panelConsole.setLayout(gbl_panelConsole);
    	add(panelConsole, gbc_panelConsole);
    	
    	
    	
    	txtaConsole = new JTextArea();
    	txtaConsole.addMouseListener(new MouseAdapter() {
    		@Override
    		public void mouseClicked(MouseEvent e) {
    			popup.show(txtaConsole,e.getX(),e.getY());
    		}
    	});
    	txtaConsole.setRows(11);
    	DefaultCaret caret = (DefaultCaret) txtaConsole.getCaret();
    	caret.setUpdatePolicy(DefaultCaret.ALWAYS_UPDATE);
    	GridBagConstraints gbc_txtaConsole = new GridBagConstraints();
    	gbc_txtaConsole.insets = new Insets(10, 10, 10, 10);
    	gbc_txtaConsole.weighty = 1.0;
    	gbc_txtaConsole.weightx = 1.0;
    	gbc_txtaConsole.fill = GridBagConstraints.BOTH;
    	gbc_txtaConsole.gridx = 0;
    	gbc_txtaConsole.gridy = 0;

    	
    	JScrollPane scrollpaneConsole  = new JScrollPane(txtaConsole);
    	scrollpaneConsole.setPreferredSize(new Dimension(400,200));
    	panelConsole.add(scrollpaneConsole, gbc_txtaConsole);

    }

    /**
     * Used to pass the param list in manually (needed for multi wp values)
     * @param params
     */
    public void sendHttpWPRequest(StringBuilder params){
    	try{

	        String getDataParams = params.toString();       
	        String sUrl = "http://" + txtfIP.getText() + ":" + txtfPort.getText() + "?" + getDataParams;
	        URL url = new URL(sUrl);
	        logToConsole("Sending HTTP request: " + sUrl);
	        
	        HttpURLConnection conn = (HttpURLConnection)url.openConnection();
	        conn.setRequestProperty("User-Agent", USER_AGENT_FIREFOX);
	        conn.setRequestMethod("GET");

	        int responseCode = conn.getResponseCode();
	        
	        logToConsole("-  Response Code :: " + responseCode);
	        
			if (responseCode == HttpURLConnection.HTTP_OK) { //success
				BufferedReader in = new BufferedReader(new InputStreamReader(
						conn.getInputStream()));
				String inputLine;
				while ((inputLine = in.readLine()) != null) {
					StringTokenizer tokenizer = new StringTokenizer(inputLine, ",");
					while(tokenizer.hasMoreTokens()){
						logToConsole("-  " + tokenizer.nextToken());
					}				
				}
				in.close();
				
			} else {
				System.out.println("-  GET request not worked");
			}
			logToConsole("");
		}
		catch(Exception ex){
			System.err.println(ex.getMessage());
		}
    }
 
    public void sendHttpRequest(Map<String,String>params){
    	try{
    		StringBuilder sGetData = new StringBuilder();
	        for (Map.Entry<String,String> param : params.entrySet()) {
	            if (sGetData.length() != 0) sGetData.append('&');
	            sGetData.append(param.getKey());
	            sGetData.append('=');
	            sGetData.append(param.getValue());
	//            postData.append(URLEncoder.encode(param.getKey(), "UTF-8"));
	//            postData.append('=');
	//            postData.append(URLEncoder.encode(String.valueOf(param.getValue()), "UTF-8"));
	        }
	        String getDataParams = sGetData.toString();
	//        byte[] postDataBytes = postData.toString().getBytes("UTF-8"); 
	                
	        String sUrl = "http://" + txtfIP.getText() + ":" + txtfPort.getText() + "?" + getDataParams;
	        URL url = new URL(sUrl);
	        logToConsole("Sending HTTP request: " + sUrl);
	        
	        HttpURLConnection conn = (HttpURLConnection)url.openConnection();
	        conn.setRequestProperty("User-Agent", USER_AGENT_FIREFOX);
	        conn.setRequestMethod("GET");
	        
	//        conn.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");
	//        conn.setRequestProperty("Content-Length", String.valueOf(sample.length()));
	//        conn.setDoOutput(true);
	//        OutputStreamWriter os = new OutputStreamWriter(conn.getOutputStream());
	//		os.write(sample);
	//		os.flush();
	//		os.close();
	        int responseCode = conn.getResponseCode();	        
			logToConsole("-  Response Code :: " + responseCode);
	        
			if (responseCode == HttpURLConnection.HTTP_OK) { //success
				BufferedReader in = new BufferedReader(new InputStreamReader(
						conn.getInputStream()));
				String inputLine;
				while ((inputLine = in.readLine()) != null) {
					StringTokenizer tokenizer = new StringTokenizer(inputLine, ",");
					while(tokenizer.hasMoreTokens()){
						logToConsole("-  " + tokenizer.nextToken());
					}				
				}
				in.close();
			} else {
				System.out.println("-- GET request not worked");
			}
			logToConsole("");
		}
		catch(Exception ex){
			System.err.println(ex.getMessage());
			logToConsole("-  " + ex.getMessage());
		}
    }
 
    /**
     * Create the GUI and show it.  For thread safety,
     * this method should be invoked from the
     * event dispatch thread.
     */
    private static void createAndShowGUI() {
        //Create and set up the window.
        JFrame frame = new JFrame("MAVLink Command HTTP Client");
        frame.setDefaultCloseOperation(JFrame.EXIT_ON_CLOSE);
 
        //Add content to the window.
        frame.getContentPane().add(new CmdGeneratorGUI());
 
        //Display the window.
        frame.pack();
        frame.setVisible(true);
    }
    
    private void logToConsole(String log){
        System.out.println(log);
        txtaConsole.append(log + "\n");
    }
 
    public static void main(String[] args) {
        //Schedule a job for the event dispatch thread:
        //creating and showing this application's GUI.
        javax.swing.SwingUtilities.invokeLater(new Runnable() {
            public void run() {
                createAndShowGUI();
            }
        });
    }
}
