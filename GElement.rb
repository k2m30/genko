
enum EType {
	cubicCurve, // C c
	cubicCurveSmooth, // S s
	ellipse, // cx cy rx ry
	line, // x1 y1 x2 y2
	quadraticCurve, // Q q
	quadraticCurveSmooth, // T t
	rectangle, // x y width height
	moveTo
};

public class GElement {
	private double p1;

	private double p2;

	private double p3;

	private double p4;

	private double p5;

	private double p6;

	private double p7;

	private double p8;

	public EType type;

	GElement(EType e, double _p1, double _p2, double _p3, double _p4) {
		p1 = _p1;
		p2 = _p2;
		p3 = _p3;
		p4 = _p4;
		type = e;
		return;
	}

	GElement(EType e, double _p1, double _p2, double _p3, double _p4,
			double _p5, double _p6) {
		p1 = _p1;
		p2 = _p2;
		p3 = _p3;
		p4 = _p4;
		p5 = _p5;
		p6 = _p6;
		type = e;
		return;
	}

	GElement(EType e, double _p1, double _p2, double _p3, double _p4,
			double _p5, double _p6, double _p7, double _p8) {
		p1 = _p1;
		p2 = _p2;
		p3 = _p3;
		p4 = _p4;
		p5 = _p5;
		p6 = _p6;
		p7 = _p7;
		p8 = _p8;
		type = e;
		return;
	}

	GElement(EType e, String _p1, String _p2, String _p3, String _p4) {
		p1 = Double.parseDouble(_p1);
		p2 = Double.parseDouble(_p2);
		p3 = Double.parseDouble(_p3);
		p4 = Double.parseDouble(_p4);
		type = e;
		return;
	}

	GElement(EType e, String _p1, String _p2, String _p3, String _p4,
			String _p5, String _p6) {
		p1 = Double.parseDouble(_p1);
		p2 = Double.parseDouble(_p2);
		p3 = Double.parseDouble(_p3);
		p4 = Double.parseDouble(_p4);
		p5 = Double.parseDouble(_p5);
		p6 = Double.parseDouble(_p6);
		type = e;
		return;
	}

	GElement(EType e, String _p1, String _p2, String _p3, String _p4,
			String _p5, String _p6, String _p7, String _p8) {
		p1 = Double.parseDouble(_p1);
		p2 = Double.parseDouble(_p2);
		p3 = Double.parseDouble(_p3);
		p4 = Double.parseDouble(_p4);
		p5 = Double.parseDouble(_p5);
		p6 = Double.parseDouble(_p6);
		p7 = Double.parseDouble(_p7);
		p8 = Double.parseDouble(_p8);
		type = e;
		return;
	}

	public double getP(int index) {
		switch (index) {
		case 1:
			return p1;
		case 2:
			return p2;
		case 3:
			return p3;
		case 4:
			return p4;
		case 5:
			return p5;
		case 6:
			return p6;
		case 7:
			return p7;
		case 8:
			return p8;
		}
		return -1;
	}

	public double getP1() {
		return p1;
	}

	public double getP2() {
		return p2;
	}

	public double getP3() {
		return p3;
	}

	public double getP4() {
		return p4;
	}

	public double getP5() {
		return p5;
	}

	public double getP6() {
		return p6;
	}

	public double getP7() {
		return p7;
	}

	public double getP8() {
		return p8;
	}

	public EType getType() {
		return type;
	}

	public void set(int index, double p) {
		switch (index) {
		case 1:
			p1 = p;
			break;
		case 2:
			p2 = p;
			break;
		case 3:
			p3 = p;
			break;
		case 4:
			p4 = p;
			break;
		}

		return;
	}

	public void setP1(double p1) {
		this.p1 = p1;
	}

	public void setP2(double p2) {
		this.p2 = p2;
	}

	public void setP3(double p3) {
		this.p3 = p3;
	}

	public void setP4(double p4) {
		this.p4 = p4;
	}

	public void setP5(double p5) {
		this.p5 = p5;
	}

	public void setP6(double p6) {
		this.p6 = p6;
	}

	public void setP7(double p7) {
		this.p7 = p7;
	}

	public void setP8(double p8) {
		this.p8 = p8;
	}

	public void setType(EType type) {
		this.type = type;
	}

	public void trace() {
		System.out.print(type.name() + ": ");
		System.out.format("%.12f ", p1);
		System.out.format("%.12f ", p2);
		System.out.format("%.12f ", p3);
		System.out.format("%.12f ", p4);
		if ((type == EType.quadraticCurve)||(type == EType.cubicCurveSmooth)||(type == EType.cubicCurve)) {
			System.out.format("%.2f ", p5);
			System.out.format("%.2f ", p6);
		}
		if (type == EType.cubicCurve) {
			System.out.format("%.12f ", p7);
			System.out.format("%.12f ", p8);
		}

		System.out.println(" ");
	}
}
