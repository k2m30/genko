XMLTree instance = new XMLTree();

String fileName = "/Users/Mikhail/git/steppers/XML/src/properties.conf";

# // читаем свойства из conf файла
drawingProperties = instance.readProperties(fileName);
if (drawingProperties == null)
	return;

# // берем файл для рисования
String svgFileName = instance.getFilename();

# // разбираем файл на элементы (линия, прямоугольник и т.д.)
ArrayList<GElement> elements = instance.parseSVGwrapper(svgFileName);

# // добавляем переходы между элементами
ArrayList<GElement> moreElements = instance.addMoveTo(elements);

# // делим элементы на небольшие линейные сегменты
ArrayList<GSegment> segments = instance.splitElementsToSegments(
		moreElements, properties.maxSegmentLength);



# // добавляем обходные пути для более плавного движения
ArrayList<GSegment> allLines = instance.addSmoothPathToLines(segments);

# //instance.listTrace(elements);
instance.segmentsTrace(allLines);

# // получение состояний длин ремней для рисования
ArrayList<GState> states = instance.makeStates(allLines);

String outputFileName = "G-code ";
# // запись G-кода в файл
outputFileName = instance.makeNGCfile(states, outputFileName);

# // создание графического файла
instance.makeSVGfile(outputFileName);

p("--------finish");


public class XMLTree {

	private static GProperties properties = new GProperties();
	protected static java.util.Properties drawingProperties;

	/**
	 * @param args
	 */
	public static void main(String[] args) {

		XMLTree instance = new XMLTree();

		String fileName = "/Users/Mikhail/git/steppers/XML/src/properties.conf";

		// читаем свойства из conf файла
		drawingProperties = instance.readProperties(fileName);
		if (drawingProperties == null)
			return;

		// берем файл для рисования
		String svgFileName = instance.getFilename();

		// разбираем файл на элементы (линия, прямоугольник и т.д.)
		ArrayList<GElement> elements = instance.parseSVGwrapper(svgFileName);

		// добавляем переходы между элементами
		ArrayList<GElement> moreElements = instance.addMoveTo(elements);

		// делим элементы на небольшие линейные сегменты
		ArrayList<GSegment> segments = instance.splitElementsToSegments(
				moreElements, properties.maxSegmentLength);

		

		// добавляем обходные пути для более плавного движения
		ArrayList<GSegment> allLines = instance.addSmoothPathToLines(segments);

		//instance.listTrace(elements);
		instance.segmentsTrace(allLines);
		
		// получение состояний длин ремней для рисования
		ArrayList<GState> states = instance.makeStates(allLines);

		String outputFileName = "G-code ";
		// запись G-кода в файл
		outputFileName = instance.makeNGCfile(states, outputFileName);

		// создание графического файла
		instance.makeSVGfile(outputFileName);

		instance.p("--------finish");

	}

	private void segmentsTrace(ArrayList<GSegment> segments) {

		if (segments == null) {
			return;
		}
		for (int i = 0; i < segments.size(); i++) {
//			p(Double.toString(segments.get(i).xStart) + " "
//					+ Double.toString(segments.get(i).yStart) + " "
//					+ Double.toString(segments.get(i).xEnd) + " "
//					+ Double.toString(segments.get(i).yEnd));
		}
	}

	private void makeSVGfile(String fileName) {
		if (fileName.isEmpty()) {
			return;
		}
		ArrayList<String> fileContent;
		try {
			fileContent = FileUtil.getFileContent(fileName);
		} catch (IOException e) {

			e.printStackTrace();
			return;
		}

		this.writeFile(fileContent, fileName);
	}

	private void writeFile(ArrayList<String> fileContent, String outputFileName) {

		File f = new File(outputFileName + ".svg");
		try {
			f.createNewFile();
			FileWriter fw = new FileWriter(f);

			fw.append("<?xml version=\"1.0\" encoding=\"utf-8\"?>");
			fw.append('\n');

			fw.append("<!DOCTYPE svg PUBLIC \"-//W3C//DTD SVG 1.1//EN\" \"http://www.w3.org/Graphics/SVG/1.1/DTD/svg11.dtd\">");
			fw.append('\n');

			fw.append("<svg version=\"1.1\" id=\"Layer_1\" xmlns=\"http://www.w3.org/2000/svg\" xmlns:xlink=\"http://www.w3.org/1999/xlink\" x=\"0px\" y=\"0px\" ");
			fw.append('\n');
			fw.append("\t ");

			fw.append("width=\"" + Double.toString(properties.canvasSizeX)
					+ "px\" ");
			fw.append("height=\"" + Double.toString(properties.canvasSizeY)
					+ "px\" ");

			fw.append("viewBox=\"0 0 "
					+ Double.toString(properties.canvasSizeX) + " "
					+ Double.toString(properties.canvasSizeY) + "\""
					+ " enable-background=\"new 0 0 "
					+ Double.toString(properties.canvasSizeX) + " "
					+ Double.toString(properties.canvasSizeY) + "\" "
					+ "xml:space=\"preserve\">");
			fw.append('\n');

			fw.append("<marker id = \"pointMarker\" viewBox = \"0 0 12 12\" refX = \"12\" refY = \"6\" markerWidth = \"3\" markerHeight = \"3\" stroke = \"green\" stroke-width = \"2\" fill = \"none\" orient = \"auto\"> "
					+ "\n"
					+ "<circle cx = \"6\" cy = \"6\" r = \"2\"/>"
					+ "\n"
					+ "</marker>");
			fw.append('\n');

			double x = (properties.canvasSizeX * properties.canvasSizeX
					- properties.initialYTicks * properties.dl
					* properties.initialYTicks * properties.dl + properties.initialXTicks
					* properties.dl * properties.initialXTicks * properties.dl)
					/ (2 * properties.canvasSizeX);
			double y = Math.sqrt(properties.initialXTicks * properties.dl
					* properties.initialXTicks * properties.dl - x * x);

			double ll = properties.initialXTicks * properties.dl;
			double lr = properties.initialYTicks * properties.dl;

			for (int i = 0; i < fileContent.size(); i++) {
				if (fileContent.get(i).contains("G00")) {
					fw.append("<line fill=\"none\" stroke=\"#FF0000\" stroke-miterlimit=\"5\" x1=\""
							+ x + "\" y1=\"" + y + "\" ");

					ll = Double.parseDouble(fileContent.get(i).substring(
							fileContent.get(i).indexOf('X') + 1,
							fileContent.get(i).indexOf('Y') - 1));
					lr = Double.parseDouble(fileContent.get(i).substring(
							fileContent.get(i).indexOf('Y') + 1,
							fileContent.get(i).indexOf('Z') - 1));

					x = (properties.canvasSizeX * properties.canvasSizeX - lr
							* lr + ll * ll)
							/ (2 * properties.canvasSizeX);
					y = Math.sqrt(ll * ll - x * x);

					fw.append("x2=\"" + x + "\" y2=\"" + y + "\" />");
					fw.append('\n');

				} else if (fileContent.get(i).contains("G01")) {
					fw.append("<line fill=\"none\" stroke=\"#000000\" marker-start = \"url(#pointMarker)\" x1=\""
							+ x + "\" y1=\"" + y + "\" ");

					ll = Double.parseDouble(fileContent.get(i).substring(
							fileContent.get(i).indexOf('X') + 1,
							fileContent.get(i).indexOf('Y') - 1));
					lr = Double.parseDouble(fileContent.get(i).substring(
							fileContent.get(i).indexOf('Y') + 1,
							fileContent.get(i).indexOf('Z') - 1));

					x = (properties.canvasSizeX * properties.canvasSizeX - lr
							* lr + ll * ll)
							/ (2 * properties.canvasSizeX);
					y = Math.sqrt(ll * ll - x * x);

					fw.append("x2=\"" + x + "\" y2=\"" + y + "\" />");
					fw.append('\n');

				}

			}

			fw.append("</svg>");
			fw.append('\n');
			fw.flush();
			fw.close();
		} catch (IOException e) {

			e.printStackTrace();
		}

	}

	private String makeNGCfile(ArrayList<GState> states, String outputFileName) {
		try {
			File f = new File(outputFileName
					+ new Date(System.currentTimeMillis()).toString() + ".ngc");
			f.createNewFile();
			FileWriter fw = new FileWriter(f);

			fw.append("%");
			fw.append('\n');
			// fw.append("G90 G40 G17 G21");
			// fw.append('\n');
			fw.append("G51Y-1");
			fw.append('\n');
			fw.append("G00 X" + states.get(0).ll + " Y" + states.get(0).lr
					+ " Z0");
			fw.append('\n');

			for (int i = 1; i < states.size(); i++) {

				if (!states.get(i).isMoveTo) { // прорисовка элементов
					fw.append("G01 X");
					fw.append(Double.toString(states.get(i).ll));
					fw.append(" Y");
					fw.append(Double.toString(states.get(i).lr));
					fw.append(" Z100");
					fw.append(" F");
					fw.append(Double.toString(properties.linearVelocity
							* states.get(i).rate));
					fw.append(" " + states.get(i).comment);
					fw.append('\n');
				} else { // быстрое перемещение между элементами
					fw.append("G00 X");
					fw.append(Double.toString(states.get(i).ll));
					fw.append(" Y");
					fw.append(Double.toString(states.get(i).lr));
					fw.append(" Z0");
					fw.append(" " + states.get(i).comment);
					fw.append('\n');
				}
			}
			fw.append("M30");
			fw.append('\n');
			fw.append("%");
			fw.append('\n');

			drawingProperties.store(fw, "drawing propreties");

			fw.flush();
			fw.close();
			outputFileName = f.getName();
		} catch (Exception ex) {
			p(ex.toString() + " makeDrawFile");
		}
		return outputFileName;

	}

	private ArrayList<GState> makeStates(ArrayList<GSegment> allLines) {
		ArrayList<GState> _states = new ArrayList<GState>();
		Iterator<GSegment> iterator;
		iterator = allLines.iterator();

		GSegment s;
		GState st;

		st = new GState(allLines.get(0).xStart, allLines.get(0).yStart,
				properties);
		_states.add(st);
		while (iterator.hasNext()) {
			s = iterator.next();
			st = new GState(s, properties);

			if (s.isMoveToSegment)
				st.isMoveTo = true;
			st.comment = s.comment;
			_states.add(st);
			// p(Double.toString(st.x) + " " + Double.toString(st.y));

		}

		return _states;
	}

	private ArrayList<GSegment> addSmoothPathToLines(
			ArrayList<GSegment> segments) {

		for (int i = 0; i < segments.size() - 1; i++) {
			double dAngle = segments.get(i).angle - segments.get(i + 1).angle;
			if (Math.abs(dAngle) > properties.changeDirectionThreshhold) {

				if ((!segments.get(i).isMoveToSegment)
						&& (!segments.get(i + 1).isMoveToSegment)) {
					ArrayList<GSegment> curve = addCurveToNearestSegments(
							segments.get(i), segments.get(i + 1));
					segments.addAll(i + 1, curve);
					i += curve.size();
				}
			}
		}

		return segments;
	}

	private ArrayList<GSegment> addCurveToNearestSegments(GSegment gSegment,
			GSegment gSegmentNext) {
		int size = 10;// Double.parseDouble(XMLTree.drawingProperties.getProperty("maxSegmentLength"));
		double[] x = new double[size + 1];
		double[] y = new double[size + 1];
		float t = 0;
		float dt = (float) (1.0 / size);

		double x0 = gSegment.xEnd;
		double y0 = gSegment.yEnd;

		double x3 = gSegmentNext.xStart;
		double y3 = gSegmentNext.yStart;

		double x1;
		double y1;
		double x2;
		double y2;

		double ratio = gSegment.segmentLength / gSegmentNext.segmentLength;
		if (ratio > 1) {
			x1 = x0 + gSegment.xEnd - gSegment.xStart;
			y1 = y0 + gSegment.yEnd - gSegment.yStart;

			x2 = x3 - (gSegmentNext.xEnd - gSegmentNext.xStart) * ratio;
			y2 = y3 - (gSegmentNext.yEnd - gSegmentNext.yStart) * ratio;
		} else {
			x1 = x0 + (gSegment.xEnd - gSegment.xStart) / ratio;
			y1 = y0 + (gSegment.yEnd - gSegment.yStart) / ratio;

			x2 = x3 - (gSegmentNext.xEnd - gSegmentNext.xStart);
			y2 = y3 - (gSegmentNext.yEnd - gSegmentNext.yStart);

		}
		for (int i = 0; i < size; i++) {
			// x = (1-t).^3.*p0(1,1) + 3*t.*(1-t).^2.*p1(1,1) +
			// 3*t.^2.*(1-t).*p2(1,1) + t.^3.*p3(1,1);
			// y = (1-t).^3.*p0(1,2) + 3*t.*(1-t).^2.*p1(1,2) +
			// 3*t.^2.*(1-t).*p2(1,2) + t.^3.*p3(1,2);

			x[i] = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t)
					* x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3;
			y[i] = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t)
					* y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3;
			t += dt;
		}

		t = 1;
		x[size] = (1 - t) * (1 - t) * (1 - t) * x0 + 3 * t * (1 - t) * (1 - t)
				* x1 + 3 * t * t * (1 - t) * x2 + t * t * t * x3;
		y[size] = (1 - t) * (1 - t) * (1 - t) * y0 + 3 * t * (1 - t) * (1 - t)
				* y1 + 3 * t * t * (1 - t) * y2 + t * t * t * y3;

		ArrayList<GSegment> segmentsList = new ArrayList<GSegment>();
		for (int i = 0; i < size; i++) {
			GSegment segment = new GSegment(x[i], y[i], x[i + 1], y[i + 1],
					properties.canvasSizeX);
			segment.isMoveToSegment = true;
			segment.comment = "(moveTo curve)";
			segmentsList.add(segment);
		}
		return segmentsList;

	}

	private ArrayList<GSegment> splitElementsToSegments(
			ArrayList<GElement> elements, double _maxSegmentLength) {
		ArrayList<GSegment> s = new ArrayList<GSegment>();

		for (int i = 0; i < elements.size(); i++) {
			GElement ge = elements.get(i);
			switch (ge.type) {
			case cubicCurve:
				break;
			case cubicCurveSmooth:
				break;
			case ellipse:
				break;
			case line:
				s.addAll(splitLineToSegments(ge, _maxSegmentLength));
				break;
			case moveTo:
				GSegment moveToSegment = new GSegment(ge.getP(1), ge.getP(2),
						ge.getP(3), ge.getP(4), properties.canvasSizeX);
				moveToSegment.isMoveToSegment = true;
				moveToSegment.comment = new String("( Angle is "
						+ moveToSegment.angle + ")");
				s.add(moveToSegment);
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

		return s;
	}

	private ArrayList<GSegment> splitLineToSegments(GElement ge,
			double _maxSegmentLength) {
		ArrayList<GSegment> s = new ArrayList<GSegment>();

		double dx = ge.getP(3) - ge.getP(1);
		double dy = ge.getP(4) - ge.getP(2);
		double l = Math.sqrt(dx * dx + dy * dy);
		int n = (int) Math.round(l / _maxSegmentLength) + 1;

		double x1 = ge.getP(1);
		double x2;
		double y1 = ge.getP(2);
		double y2;
		for (int i = 1; i <= n; i++) {
			x2 = x1 + dx / n;
			y2 = y1 + dy / n;
			GSegment segment = new GSegment(x1, y1, x2, y2,
					properties.canvasSizeX);
			segment.comment = new String("(Line " + ge.getP(1) + " "
					+ ge.getP(2) + " " + ge.getP(3) + " " + ge.getP(4) + " "
					+ "Segment #" + i + " Angle is " + segment.angle + ")");
			segment.segmentLength = Math.sqrt((x2 - x1) * (x2 - x1) + (y2 - y1)
					* (y2 - y1));
			s.add(segment);
			x1 = x2;
			y1 = y2;
		}
		return s;

	}

	private ArrayList<GElement> addMoveTo(ArrayList<GElement> elements) {

		for (int i = 0; i < elements.size() - 1; i++) {
			GElement current_el = elements.get(i);
			GElement next_el = elements.get(i + 1);
			switch (elements.get(i).type) {
			case cubicCurve:// 8 точек в элементе
				elements.add(
						i + 1,
						new GElement(EType.moveTo, current_el.getP(7),
								current_el.getP(8), next_el.getP(1), next_el
										.getP(2)));

				break;
			case cubicCurveSmooth:// 6 точек в элементе
			case quadraticCurve:
				elements.add(
						i + 1,
						new GElement(EType.moveTo, current_el.getP(5),
								current_el.getP(6), next_el.getP(1), next_el
										.getP(2)));
				break;
			case ellipse:// 4 точки в элементе
			case line:
			case quadraticCurveSmooth:
			case rectangle:
				elements.add(
						i + 1,
						new GElement(EType.moveTo, current_el.getP(3),
								current_el.getP(4), next_el.getP(1), next_el
										.getP(2)));
				break;

			case moveTo:
				break;

			default:
				break;
			}
		}

		for (int i = 0; i < elements.size(); i++) { // удаление нулевых
													// переходов (начало и конец
													// совпадают)
			if ((elements.get(i).type == EType.moveTo)
					&& (elements.get(i).getP(1) == elements.get(i).getP(3))
					&& (elements.get(i).getP(2) == elements.get(i).getP(4))) {
				elements.remove(i);
			}
		}
		return elements;
	}

	private java.util.Properties readProperties(String fileName) {

		java.util.Properties prop = new java.util.Properties();

		try {
//			Properties props = new Properties();
			prop.load(new FileInputStream(fileName));
			p(prop.entrySet().toString());
//			prop.load(getClass().getResourceAsStream(fileName));
		} catch (Exception e) {
			e.printStackTrace();
			p("Error: properties file is missing");
			return null;
		}

		properties.initialXTicks = Double.parseDouble(prop
				.getProperty("initialXTicks"));// 1000
		properties.initialYTicks = Double.parseDouble(prop
				.getProperty("initialYTicks"));// 1000;
		properties.a = Double.parseDouble(prop.getProperty("a"));// 10;
		properties.canvasSizeX = Double.parseDouble(prop
				.getProperty("canvasSizeX"));// 846;
		properties.canvasSizeY = Double.parseDouble(prop
				.getProperty("canvasSizeY"));// 1200;
		properties.linearVelocity = Double.parseDouble(prop
				.getProperty("linearVelocity"));// 15000;
		properties.maxV = Double.parseDouble(prop.getProperty("maxV"));// 250;
		properties.radius = Double.parseDouble(prop.getProperty("radius"));// 15.9;
		properties.stepsPerRound = Double.parseDouble(prop
				.getProperty("stepsPerRound"));// 200;
		properties.tickSize = Double.parseDouble(prop.getProperty("tickSize"));// 0.000250;
		properties.maxSegmentLength = Double.parseDouble(prop
				.getProperty("maxSegmentLength"));// 10;
		properties.changeDirectionThreshhold = Double.parseDouble(prop
				.getProperty("changeDirectionThreshhold"));// 0.2;

		properties.calculate();

		return prop;
	}

	private String getFilename() {

		// TODO Auto-generated method stub
		// return
		// "file:/Users/Mikhail/Documents/workspace/steppers/bin/Trifold_Brochure.svg";
		return "file:///Users/Mikhail/git/steppers/XML/src/rack.svg";
		//return "file:///Users/Mikhail/Downloads/motor.svg";
		// return "file:///Users/Mikhail/Downloads/scroll-heart.svg";
		 //return "file:///Users/Mikhail/Downloads/Cat_in_a_pan.svg";
		// return "file:///Users/Mikhail/Downloads/High_tech_coffee.svg";
		 //return "file:///Users/Mikhail/Downloads/scroll-heart-.svg";
		 //return  "file:/Users/Mikhail/Documents/workspace/steppers/bin/Domik.svg";
		 //return "file:/Users/Mikhail/Documents/Circles.svg";
	}

	private ArrayList<GElement> parseSVGwrapper(String svgFileName) {

		try {
			p(svgFileName);
			String parser = XMLResourceDescriptor.getXMLParserClassName();
			SAXSVGDocumentFactory f = new SAXSVGDocumentFactory(parser);
			String uri = svgFileName;
			Document doc = f.createDocument(uri);

			Element svg = doc.getDocumentElement();
			// Remove the xml-stylesheet PI.
			for (Node n = svg.getPreviousSibling(); n != null; n = n
					.getPreviousSibling()) {
				if (n.getNodeType() == Node.PROCESSING_INSTRUCTION_NODE) {
					doc.removeChild(n);
					break;
				}
			}
			ArrayList<GElement> list = new ArrayList<GElement>();
			list = parseSVGbody(svg);
			return list;

		} catch (Exception ex) {
			p(ex.toString() + " Parse SVG");
		}
		return null;
	}

	private ArrayList<GElement> parseSVGbody(Node n) {
		ArrayList<GElement> list = new ArrayList<GElement>();
		ArrayList<GElement> tmp = parseSVGNodeAnalysis(n);
		if (tmp != null) {
			list.addAll(tmp);
		}
		for (int i = 0; i < n.getChildNodes().getLength(); i++) {
			Node k = n.getChildNodes().item(i);
			tmp = parseSVGbody(k);
			if (tmp != null) {
				list.addAll(tmp);
			}

		}
		return list;
	}

	@SuppressWarnings("unchecked")
	private ArrayList<GElement> parseSVGNodeAnalysis(Node k) {

		if (k.getLocalName() != null) {
			p(k.getLocalName());
			ArrayList<GElement> list = new ArrayList<GElement>();
			// ///// BODY
			try {
				list = (ArrayList<GElement>) XMLTree.class.getDeclaredMethod(
						"polyline", k.getClass()).invoke(this, k);
				if (list != null) {
					list = applyCurrentTranslate(list, (SVGOMElement) k);
					list = applyCurrentScale(list, (SVGOMElement) k);
				}
				// double translate = getCurrentTranslate(k);
				// applyCurrentTranslate(list, translate);

			} catch (Exception e1) {
				e1.printStackTrace();
			}

			// ///// BODY
			return list;
		}
		return null;
	}

	private double[] getCurrentTranslate(SVGOMElement k) {

		for (SVGOMElement n = k; !n.getLocalName().equalsIgnoreCase("svg"); n = (SVGOMElement) n
				.getParentNode()) {
			String transform = n.getAttribute("transform");

			if ((transform != null) && (!transform.equals(""))) {
				transform = transform.toLowerCase();
				if (transform.contains("translate")) {
					int openBracketPosition = transform.indexOf("(",
							transform.indexOf("translate")) + 1;
					int closeBracketPosition = transform.indexOf(")",
							transform.indexOf("translate"));
					String translate = transform.substring(openBracketPosition,
							closeBracketPosition);

					String _translate[] = translate.split("[ ;,:]");
					double translateValue[] = new double[2];

					for (int i = 0; i < _translate.length; i++) {
						translateValue[i] = Double.parseDouble(_translate[i]);
						// translate(<tx> [<ty>]). If <ty> is not provided, it
						// is assumed to be zero.
					}
					if (_translate.length == 1) {
						translateValue[1] = 0;

					}

					return translateValue;
				}

			}
		}

		double translateValue[] = new double[2]; // если нет, вернуть 0
		translateValue[0] = 0;
		translateValue[1] = 0;
		return translateValue;
	}

	private double[] getCurrentScale(SVGOMElement k) {

		for (SVGOMElement n = k; !n.getLocalName().equalsIgnoreCase("svg"); n = (SVGOMElement) n
				.getParentNode()) {
			String transform = n.getAttribute("transform");

			if ((transform != null) && (!transform.equals(""))) {
				transform = transform.toLowerCase();
				if (transform.contains("scale")) {
					int openBracketPosition = transform.indexOf("(",
							transform.indexOf("scale")) + 1;
					int closeBracketPosition = transform.indexOf(")",
							transform.indexOf("scale"));
					String scale = transform.substring(openBracketPosition,
							closeBracketPosition);

					String _scale[] = scale.split("[ :,;]");
					double scaleValue[] = new double[3];

					for (int i = 0; i < _scale.length; i++) {
						scaleValue[i] = Double.parseDouble(_scale[i]);
						// scale(<sx> [<sy> [<sz>]]) If <sy> and <sz> are not
						// provided, it is assumed to be equal to <sx>.
					}
					if (_scale.length == 1) {
						scaleValue[1] = scaleValue[0];
						scaleValue[2] = scaleValue[0];
					}
					if (_scale.length == 2) {
						scaleValue[2] = scaleValue[0];
					}
					return scaleValue;
				}

			}
		}
		double scaleValue[] = new double[2]; // если нет, вернуть 1
		scaleValue[0] = 1;
		scaleValue[1] = 1;
		return scaleValue;
	}

	private ArrayList<GElement> applyCurrentTranslate(ArrayList<GElement> list,
			SVGOMElement n) {
		if (list == null) {
			return list;
		}
		double translate[] = getCurrentTranslate(n);
		if ((translate[0] == 0) && (translate[1] == 0)) {
			return list;
		}
		for (int i = 0; i < list.size(); i++) {
			list.get(i).set(1, list.get(i).getP(1) + translate[0]);
			list.get(i).set(2, list.get(i).getP(2) + translate[1]);
			list.get(i).set(3, list.get(i).getP(3) + translate[0]);
			list.get(i).set(4, list.get(i).getP(4) + translate[1]);
		}
		return list;

	}

	private ArrayList<GElement> applyCurrentScale(ArrayList<GElement> list,
			SVGOMElement n) {
		if (list == null) {
			return list;
		}
		double scale[] = getCurrentScale(n);
		if ((scale[0] == 1) && (scale[1] == 1)) {
			return list;
		}
		for (int i = 0; i < list.size(); i++) {
			list.get(i).set(1, list.get(i).getP(1) * scale[0]);
			list.get(i).set(2, list.get(i).getP(2) * scale[1]);
			list.get(i).set(3, list.get(i).getP(3) * scale[0]);
			list.get(i).set(4, list.get(i).getP(4) * scale[1]);
		}
		return list;

	}

	public void p(String str) {
		System.out.println(str);
	}

	public void listTrace(ArrayList<GElement> _list) {
		if (_list == null)
			return;
		Iterator<GElement> iterator = _list.iterator();
		while (iterator.hasNext()) {
			GElement ge = (GElement) iterator.next();
			ge.trace();
		}
		return;
	}

	public void p(int intValue) {
		System.out.println(Integer.toString(intValue));
	}

	public void p(float floatValue) {
		System.out.println(Float.toString(floatValue));
	}

	protected ArrayList<GElement> polyline(SVGOMRectElement rect) {
		p("rectangle");
		double x1 = Double.parseDouble(rect.getAttribute("x"));
		double y1 = Double.parseDouble(rect.getAttribute("y"));
		double width = Double.parseDouble(rect.getAttribute("width"));
		double heigth = Double.parseDouble(rect.getAttribute("heigth"));

		ArrayList<GElement> list = new ArrayList<GElement>();
		list.add(new GElement(EType.line, x1, y1, x1 + width, y1));
		list.add(new GElement(EType.line, x1 + width, y1, x1 + width, y1
				+ heigth));
		list.add(new GElement(EType.line, x1 + width, y1 + heigth, x1, y1
				+ heigth));
		list.add(new GElement(EType.line, x1, y1 + heigth, x1, y1));
		return list;

	}

	protected ArrayList<GElement> polyline(SVGOMLineElement line) {
		p("it works line");
		GElement el = new GElement(EType.line, line.getAttribute("x1"),
				line.getAttribute("y1"), line.getAttribute("x2"),
				line.getAttribute("y2"));
		ArrayList<GElement> list = new ArrayList<GElement>();
		list.add(el);
		return list;
	}

	protected ArrayList<GElement> polyline(SVGOMEllipseElement ellipse) {
		p("it works ellipse");
		GElement el = new GElement(EType.ellipse, ellipse.getAttribute("cx"),
				ellipse.getAttribute("cy"), ellipse.getAttribute("rx"),
				ellipse.getAttribute("ry"));
		return makeLinesListFromEllipse(el);
	}

	private ArrayList<GElement> makeLinesListFromEllipse(GElement el) {
		// TODO Auto-generated method stub
		return null;
	}

	protected ArrayList<GElement> polyline(SVGOMSVGElement svg) {
		p("it works svg");
		return null;
	}

	protected ArrayList<GElement> polyline(SVGOMGElement g) {
		p("it works g");
		return null;
	}

	protected ArrayList<GElement> polyline(SVGOMPathElement path) {

		PathParser pp = new PathParser();
		GPathHandler ph = new GPathHandler(this, path);
		pp.setPathHandler(ph);
		pp.parse(path.getAttribute("d"));
		ArrayList<GElement> pathElementList = ph.getGElementList();

		// listTrace(pathElementList);
		// String a = path.getAttribute("translate");
		return pathElementList;

	}

	protected ArrayList<GElement> polyline(GenericElementNS generic) {
		p("it works generic");
		return null;
	}

	protected ArrayList<GElement> polyline(SVGOMMetadataElement metadata) {
		p("it works metadata");
		return null;
	}

	protected ArrayList<GElement> polyline(SVGOMDefsElement defs) {
		p("it works defs");
		return null;
	}
}
