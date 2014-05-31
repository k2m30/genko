

public class GSegment {
	public double xStart;
	public double yStart;
	public double xEnd;
	public double yEnd;
	public boolean isMoveToSegment = false;
	public double segmentLength;
	public double angle;
	public String comment;

	GSegment(double _xStart, double _yStart, double _xEnd, double _yEnd, double width) {
		xStart = _xStart;
		yStart = _yStart;
		xEnd = _xEnd;
		yEnd = _yEnd;
		segmentLength = Math.sqrt((xEnd - xStart) * (xEnd - xStart)
				+ (yEnd - yStart) * (yEnd - yStart));
		calculateAngle(width);
	}

	private void calculateAngle(double width) {
		double llStart = Math.sqrt(xStart * xStart + yStart * yStart);
		double llEnd = Math.sqrt(xEnd * xEnd + yEnd * yEnd);
		
		double lrStart = Math.sqrt((width-xStart)*(width-xStart) + yStart*yStart);
		double lrEnd = Math.sqrt((width-xEnd)*(width-xEnd) + yEnd*yEnd);
		
		angle = Math.atan((llEnd - llStart)/(lrEnd - lrStart));
		if (llEnd<llStart) angle = -angle;
		if (lrEnd<lrStart) angle = -angle;
	}
}
