import java.util.ArrayList;

import org.apache.batik.dom.svg.SVGOMPathElement;
import org.apache.batik.parser.ParseException;
import org.apache.batik.parser.PathHandler;

public class GPathHandler implements PathHandler {
	/**
	 * 
	 */
	// private XMLTree xmlTree;
	// private final SVGOMPathElement path;
	private ArrayList<GElement> list = new ArrayList<GElement>();
	private float x;
	private float y;
	private float tmpX;
	private float tmpY;

	public ArrayList<GElement> getGElementList() {
		return list;
	}

	public GPathHandler(XMLTree xmlTree, SVGOMPathElement path) {
		// this.xmlTree = xmlTree;
		// this.path = path;
	}

	@Override
	public void startPath() throws ParseException {
		tmpX = Float.NaN;
		tmpY = Float.NaN;
	}

	// m
	@Override
	public void movetoRel(float arg0, float arg1) throws ParseException {

		x = x + arg0;
		y = y + arg1;
	}

	// M
	@Override
	public void movetoAbs(float arg0, float arg1) throws ParseException {

		x = arg0;
		y = arg1;
	}

	// v
	@Override
	public void linetoVerticalRel(float arg0) throws ParseException {
		list.add(new GElement(EType.line, x, y, x, y + arg0));
		y = y + arg0;

	}

	// V
	@Override
	public void linetoVerticalAbs(float arg0) throws ParseException {
		list.add(new GElement(EType.line, x, y, x, arg0));
		y = arg0;

	}

	// l
	@Override
	public void linetoRel(float arg0, float arg1) throws ParseException {

		list.add(new GElement(EType.line, x, y, x + arg0, y + arg1));
		x = x + arg0;
		y = y + arg1;
	}

	// h
	@Override
	public void linetoHorizontalRel(float arg0) throws ParseException {
		list.add(new GElement(EType.line, x, y, x + arg0, y));
		x = x + arg0;

	}

	// H
	@Override
	public void linetoHorizontalAbs(float arg0) throws ParseException {
		list.add(new GElement(EType.line, x, y, arg0, y));
		x = arg0;
	}

	// L
	@Override
	public void linetoAbs(float arg0, float arg1) throws ParseException {
		list.add(new GElement(EType.line, x, y, arg0, arg1));
		x = arg0;
		y = arg1;
	}

	@Override
	public void endPath() throws ParseException {
		makePolyline();

	}

	private void makePolyline() {
		for (int i = 0; i < list.size(); i++) {
			GElement ge = list.get(i);
			switch (ge.type) {
			case cubicCurve:
				list.addAll(i, makeLinesFromCubicCurve(ge));
				list.remove(ge);
				break;
			case cubicCurveSmooth:
				break;
			case ellipse:
				break;
			case line:
				break;
			case quadraticCurve:
				break;
			case quadraticCurveSmooth:
				break;
			case rectangle:
				break;
			default:
				break;

			}
		}

	}

	private ArrayList<GElement> makeLinesFromCubicCurve(GElement ge) {
		int size = 10;// Double.parseDouble(XMLTree.drawingProperties.getProperty("maxSegmentLength"));
		double[] x = new double[size + 1];
		double[] y = new double[size + 1];
		float t = 0;
		float dt = (float) (1.0 / size);

		for (int i = 0; i < size; i++) {
			// x = (1-t).^3.*p0(1,1) + 3*t.*(1-t).^2.*p1(1,1) +
			// 3*t.^2.*(1-t).*p2(1,1) + t.^3.*p3(1,1);
			// y = (1-t).^3.*p0(1,2) + 3*t.*(1-t).^2.*p1(1,2) +
			// 3*t.^2.*(1-t).*p2(1,2) + t.^3.*p3(1,2);

			// TODO http://www.rsdn.ru/article/multimedia/Bezier.xml

			x[i] = (1 - t) * (1 - t) * (1 - t) * ge.getP(1) + 3 * t * (1 - t)
					* (1 - t) * ge.getP(3) + 3 * t * t * (1 - t) * ge.getP(5)
					+ t * t * t * ge.getP(7);
			y[i] = (1 - t) * (1 - t) * (1 - t) * ge.getP(2) + 3 * t * (1 - t)
					* (1 - t) * ge.getP(4) + 3 * t * t * (1 - t) * ge.getP(6)
					+ t * t * t * ge.getP(8);
			t += dt;
		}

		t = 1;
		x[size] = (1 - t) * (1 - t) * (1 - t) * ge.getP(1) + 3 * t
				* (1 - t) * (1 - t) * ge.getP(3) + 3 * t * t * (1 - t)
				* ge.getP(5) + t * t * t * ge.getP(7);
		y[size] = (1 - t) * (1 - t) * (1 - t) * ge.getP(2) + 3 * t
				* (1 - t) * (1 - t) * ge.getP(4) + 3 * t * t * (1 - t)
				* ge.getP(6) + t * t * t * ge.getP(8);

		ArrayList<GElement> lineList = new ArrayList<GElement>();
		for (int i = 0; i < size; i++) {
			lineList.add(new GElement(EType.line, x[i], y[i], x[i + 1],
					y[i + 1]));
		}
		return lineList;
	}

	// t
	@Override
	public void curvetoQuadraticSmoothRel(float arg0, float arg1)
			throws ParseException {
		// TODO Auto-generated method stub

	}

	// T
	@Override
	public void curvetoQuadraticSmoothAbs(float arg0, float arg1)
			throws ParseException {
		// TODO Auto-generated method stub

	}

	// q
	@Override
	public void curvetoQuadraticRel(float arg0, float arg1, float arg2,
			float arg3) throws ParseException {
		list.add(new GElement(EType.quadraticCurve, x, y, x + arg0, y + arg1, x
				+ arg2, y + arg3));
		x = x + arg2;
		y = y + arg3;

	}

	// Q
	@Override
	public void curvetoQuadraticAbs(float arg0, float arg1, float arg2,
			float arg3) throws ParseException {
		list.add(new GElement(EType.quadraticCurve, x, y, arg0, arg1, arg2,
				arg3));
		x = arg2;
		y = arg3;

	}

	// s
	@Override
	public void curvetoCubicSmoothRel(float arg0, float arg1, float arg2,
			float arg3) throws ParseException {

		if (tmpX == Float.NaN) {
			tmpX = x;
		}
		if (tmpY == Float.NaN) {
			tmpY = y;
		}

		float dx = x - tmpX;
		float dy = y - tmpY;

		float xReflected = x + dx;
		float yReflected = y + dy;

		list.add(new GElement(EType.cubicCurve, x, y, xReflected, yReflected, x
				+ arg0, y + arg1, x + arg2, y + arg3));

		tmpX = x + arg0;
		tmpY = y + arg1;
		x = x + arg2;
		y = y + arg3;

	}

	// S
	@Override
	public void curvetoCubicSmoothAbs(float arg0, float arg1, float arg2,
			float arg3) throws ParseException {
		if (tmpX == Float.NaN) {
			tmpX = x;
		}
		if (tmpY == Float.NaN) {
			tmpY = y;
		}

		float dx = x - tmpX;
		float dy = y - tmpY;

		float xReflected = x + dx;
		float yReflected = y + dy;

		list.add(new GElement(EType.cubicCurve, x, y, xReflected, yReflected,
				arg0, arg1, arg2, arg3));

		tmpX = arg0;
		tmpY = arg1;
		x = arg2;
		y = arg3;

	}

	// c
	@Override
	public void curvetoCubicRel(float arg0, float arg1, float arg2, float arg3,
			float arg4, float arg5) throws ParseException {
		list.add(new GElement(EType.cubicCurve, x, y, x + arg0, y + arg1, x
				+ arg2, y + arg3, x + arg4, y + arg5));

		tmpX = x + arg2;
		tmpY = y + arg3;
		x = x + arg4;
		y = y + arg5;

	}

	// C
	@Override
	public void curvetoCubicAbs(float arg0, float arg1, float arg2, float arg3,
			float arg4, float arg5) throws ParseException {
		list.add(new GElement(EType.cubicCurve, x, y, arg0, arg1, arg2, arg3,
				arg4, arg5));
		tmpX = arg2;
		tmpY = arg3;
		x = arg4;
		y = arg5;

	}

	@Override
	public void closePath() throws ParseException {
		tmpX = Float.NaN;
		tmpY = Float.NaN;

	}

	// a
	@Override
	public void arcRel(float arg0, float arg1, float arg2, boolean arg3,
			boolean arg4, float arg5, float arg6) throws ParseException {
		// TODO Auto-generated method stub

	}

	// A
	@Override
	public void arcAbs(float arg0, float arg1, float arg2, boolean arg3,
			boolean arg4, float arg5, float arg6) throws ParseException {
		// TODO Auto-generated method stub

	}
}