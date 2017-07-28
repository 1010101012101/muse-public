/*
 * Copyright (c) 2014-2017 Leidos.
 * 
 * License: 3-clause BSD, see https://opensource.org/licenses/BSD-3-Clause
 */
/*
 * Developed under contract #FA8750-14-C-0241
 */
package com.leidos.muse.mapping;

import java.awt.Color;
import java.awt.Dimension;
import java.awt.Font;
import java.awt.GradientPaint;
import java.awt.GridLayout;
import java.awt.Point;
import java.text.DecimalFormat;
import java.text.NumberFormat;

import javax.swing.JFrame;
import javax.swing.JPanel;
import javax.swing.JSlider;

import org.jfree.chart.ChartPanel;
import org.jfree.chart.JFreeChart;
import org.jfree.chart.plot.dial.DialBackground;
import org.jfree.chart.plot.dial.DialCap;
import org.jfree.chart.plot.dial.DialPlot;
import org.jfree.chart.plot.dial.DialTextAnnotation;
import org.jfree.chart.plot.dial.DialValueIndicator;
import org.jfree.chart.plot.dial.StandardDialFrame;
import org.jfree.chart.plot.dial.StandardDialRange;
import org.jfree.chart.plot.dial.StandardDialScale;
import org.jfree.data.general.DefaultValueDataset;
import org.jfree.data.general.ValueDataset;
import org.jfree.ui.GradientPaintTransformType;
import org.jfree.ui.StandardGradientPaintTransformer;

public class DialsVHUD extends JFrame
{
	private DemoPanel panel = null;
	static class DemoPanel extends JPanel
	{
		
		private DefaultValueDataset datasetRoll;
		private DefaultValueDataset datasetPitch;
		private DefaultValueDataset datasetYaw;
		private DefaultValueDataset datasetAlt;
		private DefaultValueDataset datasetBattery;
		private DefaultValueDataset datasetThrottle;

		JSlider slider;
		DefaultValueDataset dataset;
		

		public static JFreeChart createStandardDialChart(String s, String s1, ValueDataset valuedataset, double d, double d1, double d2, int i)
		{
			DialPlot dialplot = new DialPlot();
			dialplot.setDataset(valuedataset);
			dialplot.setDialFrame(new StandardDialFrame());
			dialplot.setBackground(new DialBackground());
			DialTextAnnotation dialtextannotation = new DialTextAnnotation(s1);
			dialtextannotation.setFont(new Font("Dialog", 1, 14));
			dialtextannotation.setRadius(0.69999999999999996D);
			dialplot.addLayer(dialtextannotation);
			DialValueIndicator dialvalueindicator = new DialValueIndicator(0);
			dialplot.addLayer(dialvalueindicator);
			StandardDialScale standarddialscale = new StandardDialScale(d, d1, -120D, -300D, 10D, 4);
			standarddialscale.setMajorTickIncrement(d2);
			standarddialscale.setMinorTickCount(i);
			standarddialscale.setTickRadius(0.88D);
			standarddialscale.setTickLabelOffset(0.14999999999999999D);
			standarddialscale.setTickLabelFont(new Font("Dialog", 0, 14));
			dialplot.addScale(0, standarddialscale);
			dialplot.addPointer(new org.jfree.chart.plot.dial.DialPointer.Pin());
			DialCap dialcap = new DialCap();
			dialplot.setCap(dialcap);
			return new JFreeChart(s, dialplot);
		}

		public void updateHUD(double roll, double pitch, double yaw)
		{

			datasetRoll.setValue(roll*180/Math.PI);
			datasetPitch.setValue(pitch*180/Math.PI);
			datasetYaw.setValue(yaw*180/Math.PI);
//			datasetHDG.setValue(alt);
		}
		
		public void updateHUD2(double hdg, double alt, double throttle)
		{

			datasetAlt.setValue(alt*3.2808399);
			datasetThrottle.setValue(throttle);
		}
		public void updateHUD3(double battery)
		{
			datasetBattery.setValue(battery);
		}

		public DemoPanel()
		{
			//super(new BorderLayout());
			super(new GridLayout(2,3));
			setPreferredSize(new Dimension(900,600));
			dataset = new DefaultValueDataset(10D);
			
	         datasetRoll = new DefaultValueDataset(0.00);
	         datasetPitch = new DefaultValueDataset(0.00D);
	         datasetYaw = new DefaultValueDataset(0.00D);
	         datasetAlt = new DefaultValueDataset(0.00D);
	         datasetThrottle = new DefaultValueDataset(0.00D);
	         datasetBattery = new DefaultValueDataset(0.00D);
	                     
	         DialPlot dialRoll = createDialPlot(new StandardDialScale(-90D, 90D, -120D, -300D, 15D, 2), "degrees");
	         dialRoll.setDataset(datasetRoll);
	         
	         DialPlot dialPitch = createDialPlot(new StandardDialScale(-90D, 90D, -120D, -300D, 15D, 2), "degrees");
	         dialPitch.setDataset(datasetPitch);
	         
	         DialPlot dialYaw = createDialPlot(new StandardDialScale(0, 360, 90D, -360D, 30D, 2), "degrees");
	         dialYaw.setDataset(datasetYaw);

	         DialPlot dialAlt = createDialPlot(new StandardDialScale(0, 100, 90D, -360D, 10D, 1), "feet");
	         dialAlt.setDataset(datasetAlt);
	         
	         DialPlot dialThr = createDialPlot(new StandardDialScale(0, 100, 90D, -360D, 10D, 1), "percent");
	         dialThr.setDataset(datasetThrottle);
	         
	         DialPlot dialBatt = createDialPlot(new StandardDialScale(0, 100, 90D, -360D, 10D, 1), "percent");
	         dialBatt.setDataset(datasetBattery);
	         
	         JFreeChart jfreechart1 = new JFreeChart(dialRoll);
	         jfreechart1.setTitle("Roll");
	         
	         JFreeChart jfreechart2 = new JFreeChart(dialPitch);
	         jfreechart2.setTitle("Pitch");
	         
	         JFreeChart jfreechart3 = new JFreeChart(dialYaw);
	         jfreechart3.setTitle("Yaw");
	         
	         JFreeChart jfreechart4 = new JFreeChart(dialAlt);
	         jfreechart4.setTitle("Altitude");
	         
	         JFreeChart jfreechart5 = new JFreeChart(dialThr);
	         jfreechart5.setTitle("Throttle");
	         
	         JFreeChart jfreechart6 = new JFreeChart(dialBatt);
	         jfreechart6.setTitle("Battery");
			
//			JFreeChart jfreechart = createStandardDialChart("Dial Demo 1", "Temperature", dataset, -40D, 60D, 10D, 4);
//			DialPlot dialplot = (DialPlot)jfreechart.getPlot();
//			
//			StandardDialRange standarddialrange = new StandardDialRange(40D, 60D, Color.red);
//			standarddialrange.setInnerRadius(0.52000000000000002D);
//			standarddialrange.setOuterRadius(0.55000000000000004D);
//			dialplot.addLayer(standarddialrange);
//			StandardDialRange standarddialrange1 = new StandardDialRange(10D, 40D, Color.orange);
//			standarddialrange1.setInnerRadius(0.52000000000000002D);
//			standarddialrange1.setOuterRadius(0.55000000000000004D);
//			dialplot.addLayer(standarddialrange1);
//			StandardDialRange standarddialrange2 = new StandardDialRange(-40D, 10D, Color.green);
//			standarddialrange2.setInnerRadius(0.52000000000000002D);
//			standarddialrange2.setOuterRadius(0.55000000000000004D);
//			dialplot.addLayer(standarddialrange2);
//			GradientPaint gradientpaint = new GradientPaint(new Point(), new Color(255, 255, 255), new Point(), new Color(170, 170, 220));
//			DialBackground dialbackground = new DialBackground(gradientpaint);
//			dialbackground.setGradientPaintTransformer(new StandardGradientPaintTransformer(GradientPaintTransformType.VERTICAL));
//			dialplot.setBackground(dialbackground);
//			dialplot.removePointer(0);
//			org.jfree.chart.plot.dial.DialPointer.Pointer pointer = new org.jfree.chart.plot.dial.DialPointer.Pointer();
//			pointer.setFillPaint(Color.yellow);
//			dialplot.addPointer(pointer);
//			ChartPanel chartpanel0 = new ChartPanel(jfreechart);
//			chartpanel0.setPreferredSize(new Dimension(300, 300));
			
			ChartPanel chartpanel = new ChartPanel(jfreechart1);
			chartpanel.setPreferredSize(new Dimension(300, 300));
			
			ChartPanel chartpanel2 = new ChartPanel(jfreechart2);
			chartpanel.setPreferredSize(new Dimension(300, 300));
			
			ChartPanel chartpanel3 = new ChartPanel(jfreechart3);
			chartpanel.setPreferredSize(new Dimension(300, 300));
			
			ChartPanel chartpanel4 = new ChartPanel(jfreechart4);
			chartpanel.setPreferredSize(new Dimension(300, 300));
			
			ChartPanel chartpanel5 = new ChartPanel(jfreechart5);
			chartpanel.setPreferredSize(new Dimension(300, 300));
			
			ChartPanel chartpanel6 = new ChartPanel(jfreechart6);
			chartpanel.setPreferredSize(new Dimension(300, 300));

			add(chartpanel);
			add(chartpanel2);
			add(chartpanel3);
			add(chartpanel4);
			add(chartpanel5);
			add(chartpanel6);


		}
		
		private DialPlot createDialPlot(StandardDialScale standarddialscale, String label){
	        DialPlot dialplot = new DialPlot();
	        dialplot.setView(0.0D, 0.0D, 1.0D, 1.0D);
	       // dialplot.setDataset(0, datasetRoll);
	        
	        StandardDialFrame standarddialframe = new StandardDialFrame();
	        standarddialframe.setBackgroundPaint(Color.lightGray);
	        standarddialframe.setForegroundPaint(Color.darkGray);
	        dialplot.setDialFrame(standarddialframe);
	        
	        GradientPaint gradientpaint = new GradientPaint(new Point(), 
	       		 new Color(255, 255, 255), new Point(), new Color(170, 170, 220));
	        DialBackground dialbackground = new DialBackground(gradientpaint);
	 //       dialbackground.setGradientPaintTransformer(
	 //      		 new StandardGradientPaintTransformer(GradientPaintTransformType.VERTICAL));
	        dialplot.setBackground(dialbackground);
	        
	        
	        DialTextAnnotation dialtextannotation = new DialTextAnnotation(label);
	        dialtextannotation.setFont(new Font("Dialog", 1, 14));
	        if(standarddialscale.getMajorTickIncrement() > 2D){
	        	dialtextannotation.setRadius(0.4189999999999999996D);
	        }
	        else{
	        	dialtextannotation.setRadius(0.69999999999999996D);
	        }
	        
	        dialplot.addLayer(dialtextannotation);
	        
	        DialValueIndicator dialvalueindicator = new DialValueIndicator(0);
	        dialvalueindicator.setFont(new Font("Dialog", 0, 12));
	        dialvalueindicator.setOutlinePaint(Color.darkGray);
	        if(standarddialscale.getMajorTickIncrement() > 2D){
	        	dialvalueindicator.setRadius(0.289999999999999996D);
	        }
	        else{
	        	dialvalueindicator.setRadius(0.59999999999999998D);
	        }
	        NumberFormat formatter = DecimalFormat.getInstance();
	        formatter.setMinimumFractionDigits(2);
	        dialvalueindicator.setNumberFormat(formatter);
	        dialvalueindicator.setAngle(-90D);
	        dialplot.addLayer(dialvalueindicator);

	        // OUTER DIAL
	        standarddialscale.setTickRadius(0.89D);
	        standarddialscale.setTickLabelOffset(0.18999999999999999D);
	        standarddialscale.setTickLabelFont(new Font("Dialog", 0, 13));
	        if(standarddialscale.getMajorTickIncrement() > 2D){
	        	standarddialscale.setFirstTickLabelVisible(false);
	        }
	        dialplot.addScale(0, standarddialscale);

	        org.jfree.chart.plot.dial.DialPointer.Pointer pointer = new org.jfree.chart.plot.dial.DialPointer.Pointer(0);
	        pointer.setWidthRadius(0.01);
	        dialplot.addPointer(pointer);
	        
	        DialCap dialcap = new DialCap();
	        dialcap.setRadius(0.10000000000000001D);
	        dialplot.setCap(dialcap);
	        
	        return dialplot;
		}
	}
	
	


	public DialsVHUD(String s)
	{
		super(s);
		setDefaultCloseOperation(3);
		panel = new DemoPanel();
		setContentPane(panel);
	}


	
	public void updateHUD(double roll, double pitch, double yaw){
		panel.updateHUD(roll, pitch, yaw);
	}
	public void updateHUD2(double hdg, double alt, double throttle){
		panel.updateHUD2(hdg, alt, throttle);
	}
	public void updateHUD3(double battery){
		panel.updateHUD3(battery);
	}

	public static void main(String args[])
	{
		DialsVHUD DialsVHUD = new DialsVHUD("JFreeChart - Demo Dial 1");
		DialsVHUD.pack();
		DialsVHUD.setVisible(true);
	}
}