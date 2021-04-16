
--DECLARE @Exx xml = '<LineString xmlns="http://www.opengis.net/gml"><posList>98660.44 926076.38 98958.12 926124.47 98980 926128 99010 926138 99062 926141 99105 926151 99139 926150 99200 926163 99238 926148 99252.27 926148.29</posList></LineString>';

--SELECT Oki = geometry::GeomFromGml(@Exx, 4277).ToString();

--DECLARE @g geography;  
--DECLARE @x xml;  
--SET @x = '<LineString xmlns="http://www.opengis.net/gml"><posList>47.656 -122.36 47.656 -122.343</posList></LineString>';  
--SET @g = geography::GeomFromGml(@x, 4326);
--SELECT @g.ToString();

DECLARE @GeeEmmEll xml =
'<?xml version="1.0" encoding="UTF-8"?>
<os:FeatureCollection xmlns:tn-ro="urn:x-inspire:specification:gmlas:RoadTransportNetwork:3.0" xmlns:gmd="http://www.isotc211.org/2005/gmd" xmlns:tn="urn:x-inspire:specification:gmlas:CommonTransportElements:3.0" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:highway="http://namespaces.os.uk/mastermap/highwayNetwork/1.0" xmlns:net="urn:x-inspire:specification:gmlas:Network:3.2" xmlns:gts="http://www.isotc211.org/2005/gts" xmlns:base="urn:x-inspire:specification:gmlas:BaseTypes:3.2" xmlns:os="http://namespaces.os.uk/product/1.0" xmlns:gsr="http://www.isotc211.org/2005/gsr" xmlns:gmlxbt="http://www.opengis.net/gml/3.3/xbt" xmlns:gco="http://www.isotc211.org/2005/gco" xmlns:road="http://namespaces.os.uk/Open/Roads/1.0" xmlns:gml="http://www.opengis.net/gml/3.2" xmlns:gn="urn:x-inspire:specification:gmlas:GeographicalNames:3.0" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:gss="http://www.isotc211.org/2005/gss" gml:id="OSOpenRoads" xsi:schemaLocation="http://namespaces.os.uk/Open/Roads/1.0 https://www.ordnancesurvey.co.uk/xml/open/roads/1.0/OSOpenRoads.xsd">
	<gml:boundedBy>
		<gml:Envelope srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
			<gml:lowerCorner>9123 899133</gml:lowerCorner>
			<gml:upperCorner>101854 929405</gml:upperCorner>
		</gml:Envelope>
	</gml:boundedBy>
	<os:metadata xlink:href="http://www.os.uk/xml/products/OSOpenRoads.xml"/>
	<os:featureMember>
		<road:RoadLink gml:id="idB865B1BF-5A8B-4015-82C2-3BD7384FE90D">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:centrelineGeometry>
				<gml:LineString gml:id="idB865B1BF-5A8B-4015-82C2-3BD7384FE90D-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:posList>98660.44 926076.38 98958.12 926124.47 98980 926128 99010 926138 99062 926141 99105 926151 99139 926150 99200 926163 99238 926148 99252.27 926148.29</gml:posList>
				</gml:LineString>
			</net:centrelineGeometry>
			<net:fictitious>false</net:fictitious>
			<net:endNode xlink:href="#idA6B49C79-2926-4442-9CAF-31D5D01AACC2"/>
			<net:startNode xlink:href="#id57F6081B-6AED-495E-A8D6-2140F4C6FA26"/>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<road:roadClassification codeSpace="http://www.os.uk/xml/codelists/RoadClassificationValue.xml">Unknown</road:roadClassification>
			<road:roadFunction codeSpace="http://www.os.uk/xml/codelists/RoadFunctionValue.xml">Minor Road</road:roadFunction>
			<road:formOfWay codeSpace="http://www.os.uk/xml/codelists/FormOfWayTypeValue.xml">Single Carriageway</road:formOfWay>
			<road:length uom="m">603</road:length>
			<road:loop>false</road:loop>
			<road:primaryRoute>false</road:primaryRoute>
			<road:trunkRoad>false</road:trunkRoad>
		</road:RoadLink>
	</os:featureMember>
	<os:featureMember>
		<road:RoadLink gml:id="id4021FE4A-2E8A-462A-88CE-39DC17E4B93D">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:centrelineGeometry>
				<gml:LineString gml:id="id4021FE4A-2E8A-462A-88CE-39DC17E4B93D-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:posList>98956.87 912358.01 98953.37 912330.68 98952 912320 98960 912306</gml:posList>
				</gml:LineString>
			</net:centrelineGeometry>
			<net:fictitious>false</net:fictitious>
			<net:endNode xlink:href="#id75CF6588-B0C0-4416-A051-84FF89AA91E3"/>
			<net:startNode xlink:href="#id2A3412FF-D0D2-4103-9037-D10D0BFA801F"/>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<road:roadClassification codeSpace="http://www.os.uk/xml/codelists/RoadClassificationValue.xml">Unknown</road:roadClassification>
			<road:roadFunction codeSpace="http://www.os.uk/xml/codelists/RoadFunctionValue.xml">Restricted Local Access Road</road:roadFunction>
			<road:formOfWay codeSpace="http://www.os.uk/xml/codelists/FormOfWayTypeValue.xml">Single Carriageway</road:formOfWay>
			<road:length uom="m">54</road:length>
			<road:loop>false</road:loop>
			<road:primaryRoute>false</road:primaryRoute>
			<road:trunkRoad>false</road:trunkRoad>
		</road:RoadLink>
	</os:featureMember>
	<os:featureMember>
		<road:RoadLink gml:id="idA177191F-3B5D-4C21-9F7B-838F7AB259EE">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:centrelineGeometry>
				<gml:LineString gml:id="idA177191F-3B5D-4C21-9F7B-838F7AB259EE-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:posList>98960 912306 99006 912285 99072.43 912197.09 99143.85 912102.57 99169.6 912068.49</gml:posList>
				</gml:LineString>
			</net:centrelineGeometry>
			<net:fictitious>false</net:fictitious>
			<net:endNode xlink:href="#idB1EDF3A4-DAC6-41D1-B200-1E7C2E6BBB52"/>
			<net:startNode xlink:href="#id75CF6588-B0C0-4416-A051-84FF89AA91E3"/>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<road:roadClassification codeSpace="http://www.os.uk/xml/codelists/RoadClassificationValue.xml">Unknown</road:roadClassification>
			<road:roadFunction codeSpace="http://www.os.uk/xml/codelists/RoadFunctionValue.xml">Local Access Road</road:roadFunction>
			<road:formOfWay codeSpace="http://www.os.uk/xml/codelists/FormOfWayTypeValue.xml">Single Carriageway</road:formOfWay>
			<road:length uom="m">322</road:length>
			<road:loop>false</road:loop>
			<road:primaryRoute>false</road:primaryRoute>
			<road:trunkRoad>false</road:trunkRoad>
		</road:RoadLink>
	</os:featureMember>
	<os:featureMember>
		<road:RoadLink gml:id="idD9B0A924-4E18-4B44-996B-61BFFD96D236">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:centrelineGeometry>
				<gml:LineString gml:id="idD9B0A924-4E18-4B44-996B-61BFFD96D236-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:posList>99169.6 912068.49 99076.32 912055.49 98983.03 912042.5</gml:posList>
				</gml:LineString>
			</net:centrelineGeometry>
			<net:fictitious>false</net:fictitious>
			<net:endNode xlink:href="#id657D6EB9-A9B2-4A40-B1F8-62B9F4BA0211"/>
			<net:startNode xlink:href="#idB1EDF3A4-DAC6-41D1-B200-1E7C2E6BBB52"/>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<road:roadClassification codeSpace="http://www.os.uk/xml/codelists/RoadClassificationValue.xml">B Road</road:roadClassification>
			<road:roadFunction codeSpace="http://www.os.uk/xml/codelists/RoadFunctionValue.xml">B Road</road:roadFunction>
			<road:formOfWay codeSpace="http://www.os.uk/xml/codelists/FormOfWayTypeValue.xml">Single Carriageway</road:formOfWay>
			<road:roadClassificationNumber>B887</road:roadClassificationNumber>
			<road:length uom="m">188</road:length>
			<road:loop>false</road:loop>
			<road:primaryRoute>false</road:primaryRoute>
			<road:trunkRoad>false</road:trunkRoad>
			<road:roadNumberTOID xlink:href="#osgb4000000003308265"/>
		</road:RoadLink>
	</os:featureMember>
	<os:featureMember>
		<road:RoadLink gml:id="id35EA8F40-0301-451D-AD64-BD91508B18AA">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:centrelineGeometry>
				<gml:LineString gml:id="id35EA8F40-0301-451D-AD64-BD91508B18AA-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:posList>99345.4 923426.37 99351 923444.71 99349 923503 99339 923538 99312 923592 99293.18 923670.86 99291.21 923679.13 99291 923680 99287.96 923684.56 99283 923692 99240 923717 99214 923742 99213.46 923743.71 99191.4 923812.88 99215 923860 99231 923923 99200 924017 99203 924031 99220 924050 99221 924066 99209 924084 99196 924102 99203 924177 99246 924209 99248 924223 99147 924263 99131 924284 99127 924301 99134 924332 99162 924375 99185 924444 99183 924490 99163 924559 99184.29 924694.36 99191 924737 99184 924819 99155 924881 99145 924949 99107.5 925021.83 99102.84 925043.14 99102.09 925059.95 99096.21 925191.63 99101.07 925440.89 99162.12 925614.44 99176.07 925672.94 99184.37 925684.37 99186.81 925687.72 99195 925699 99230.22 925845.74 99252.27 926148.29</gml:posList>
				</gml:LineString>
			</net:centrelineGeometry>
			<net:fictitious>false</net:fictitious>
			<net:endNode xlink:href="#idA6B49C79-2926-4442-9CAF-31D5D01AACC2"/>
			<net:startNode xlink:href="#idFF63D222-6E37-4191-A914-B8FCCF8C2294"/>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<road:roadClassification codeSpace="http://www.os.uk/xml/codelists/RoadClassificationValue.xml">Unknown</road:roadClassification>
			<road:roadFunction codeSpace="http://www.os.uk/xml/codelists/RoadFunctionValue.xml">Minor Road</road:roadFunction>
			<road:formOfWay codeSpace="http://www.os.uk/xml/codelists/FormOfWayTypeValue.xml">Single Carriageway</road:formOfWay>
			<road:length uom="m">2957</road:length>
			<road:loop>false</road:loop>
			<road:primaryRoute>false</road:primaryRoute>
			<road:trunkRoad>false</road:trunkRoad>
		</road:RoadLink>
	</os:featureMember>
	<os:featureMember>
		<road:RoadLink gml:id="id6957860D-58DD-42B2-824A-00D1CF8DA19B">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:centrelineGeometry>
				<gml:LineString gml:id="id6957860D-58DD-42B2-824A-00D1CF8DA19B-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:posList>99169.6 912068.49 99209 912063.04 99248.4 912057.59 99322 912046 99348 912006 99498 911820 99567 911755 99610 911676 99670 911538 99678 911482 99700 911403 99755 911342 99802 911303 99878 911184 99930 911115 100000 910998 100018 910945 100049 910905 100160 910811 100217 910749 100349.6 910644.67 100353 910642 100367 910625 100393 910569 100440 910529 100484 910507 100604 910470 100668 910436 100746 910416 100816 910373 100891 910337 101120 910246 101177.38 910232.43 101224 910216 101327 910160 101415 910060 101547 909941 101729 909808 101813 909718 101854 909658</gml:posList>
				</gml:LineString>
			</net:centrelineGeometry>
			<net:fictitious>false</net:fictitious>
			<net:endNode xlink:href="#idE5496E8C-DBA1-4854-9758-54F9CF4BFB58"/>
			<net:startNode xlink:href="#idB1EDF3A4-DAC6-41D1-B200-1E7C2E6BBB52"/>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<road:roadClassification codeSpace="http://www.os.uk/xml/codelists/RoadClassificationValue.xml">B Road</road:roadClassification>
			<road:roadFunction codeSpace="http://www.os.uk/xml/codelists/RoadFunctionValue.xml">B Road</road:roadFunction>
			<road:formOfWay codeSpace="http://www.os.uk/xml/codelists/FormOfWayTypeValue.xml">Single Carriageway</road:formOfWay>
			<road:roadClassificationNumber>B887</road:roadClassificationNumber>
			<road:length uom="m">3774</road:length>
			<road:loop>false</road:loop>
			<road:primaryRoute>false</road:primaryRoute>
			<road:trunkRoad>false</road:trunkRoad>
			<road:roadNumberTOID xlink:href="#osgb4000000003308265"/>
		</road:RoadLink>
	</os:featureMember>
	<os:featureMember>
		<road:RoadLink gml:id="id57CE72D9-B7EA-4C8D-902E-EE537B8AFA10">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:centrelineGeometry>
				<gml:LineString gml:id="id57CE72D9-B7EA-4C8D-902E-EE537B8AFA10-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:posList>100061 929405 100046 929379 100032 929298 100000 929262 99877 929160 99831 929067 99818 929023 99818 928975 99846 928781 99890 928698 99900 928662 99901 928626 99894 928605 99874 928570 99830 928517 99631.1 928321.37 99479.99 928123.85 99401.39 928009.09 99381.69 927954.46 99378.55 927900.37 99368.79 927732.36 99359.34 927679.35 99324 927591 99208.03 927367.27 99226.31 927057.13 99268.35 926628.98 99270.08 926400.08 99252.27 926148.29</gml:posList>
				</gml:LineString>
			</net:centrelineGeometry>
			<net:fictitious>false</net:fictitious>
			<net:endNode xlink:href="#idA6B49C79-2926-4442-9CAF-31D5D01AACC2"/>
			<net:startNode xlink:href="#id7251255E-C623-418B-B64D-2C21DC26819D"/>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<road:roadClassification codeSpace="http://www.os.uk/xml/codelists/RoadClassificationValue.xml">Unknown</road:roadClassification>
			<road:roadFunction codeSpace="http://www.os.uk/xml/codelists/RoadFunctionValue.xml">Minor Road</road:roadFunction>
			<road:formOfWay codeSpace="http://www.os.uk/xml/codelists/FormOfWayTypeValue.xml">Single Carriageway</road:formOfWay>
			<road:length uom="m">3583</road:length>
			<road:loop>false</road:loop>
			<road:primaryRoute>false</road:primaryRoute>
			<road:trunkRoad>false</road:trunkRoad>
		</road:RoadLink>
	</os:featureMember>
	<os:featureMember>
		<road:RoadLink gml:id="id75DAE1F2-888C-4220-A99D-190ECA0C6A4B">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:centrelineGeometry>
				<gml:LineString gml:id="id75DAE1F2-888C-4220-A99D-190ECA0C6A4B-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:posList>9242 899133 9196 899166 9149 899232 9133 899279 9123 899357 9128 899364 9161 899369 9158 899397 9190 899414 9247.45 899602.52 9254 899624 9263 899729 9264 899854 9305 899946 9297 900000 9291 900079 9299.76 900160.53</gml:posList>
				</gml:LineString>
			</net:centrelineGeometry>
			<net:fictitious>false</net:fictitious>
			<net:endNode xlink:href="#id62F323B2-7782-454B-88CC-94105DF52097"/>
			<net:startNode xlink:href="#id3FEF2A4C-92B0-41C8-9B01-588701F90B7E"/>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<road:roadClassification codeSpace="http://www.os.uk/xml/codelists/RoadClassificationValue.xml">Unknown</road:roadClassification>
			<road:roadFunction codeSpace="http://www.os.uk/xml/codelists/RoadFunctionValue.xml">Restricted Local Access Road</road:roadFunction>
			<road:formOfWay codeSpace="http://www.os.uk/xml/codelists/FormOfWayTypeValue.xml">Single Carriageway</road:formOfWay>
			<road:length uom="m">1139</road:length>
			<road:loop>false</road:loop>
			<road:primaryRoute>false</road:primaryRoute>
			<road:trunkRoad>false</road:trunkRoad>
		</road:RoadLink>
	</os:featureMember>
	<os:featureMember>
		<road:RoadNode gml:id="id57F6081B-6AED-495E-A8D6-2140F4C6FA26">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:geometry>
				<gml:Point gml:id="id57F6081B-6AED-495E-A8D6-2140F4C6FA26-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:pos>98660.44 926076.38</gml:pos>
				</gml:Point>
			</net:geometry>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<tn-ro:formOfRoadNode codeSpace="http://inspire.ec.europa.eu/codelist/FormOfRoadNodeValue">road end</tn-ro:formOfRoadNode>
		</road:RoadNode>
	</os:featureMember>
	<os:featureMember>
		<road:RoadNode gml:id="id2A3412FF-D0D2-4103-9037-D10D0BFA801F">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:geometry>
				<gml:Point gml:id="id2A3412FF-D0D2-4103-9037-D10D0BFA801F-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:pos>98956.87 912358.01</gml:pos>
				</gml:Point>
			</net:geometry>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<tn-ro:formOfRoadNode codeSpace="http://inspire.ec.europa.eu/codelist/FormOfRoadNodeValue">road end</tn-ro:formOfRoadNode>
		</road:RoadNode>
	</os:featureMember>
	<os:featureMember>
		<road:RoadNode gml:id="id75CF6588-B0C0-4416-A051-84FF89AA91E3">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:geometry>
				<gml:Point gml:id="id75CF6588-B0C0-4416-A051-84FF89AA91E3-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:pos>98960 912306</gml:pos>
				</gml:Point>
			</net:geometry>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<tn-ro:formOfRoadNode codeSpace="http://inspire.ec.europa.eu/codelist/FormOfRoadNodeValue">pseudo node</tn-ro:formOfRoadNode>
		</road:RoadNode>
	</os:featureMember>
	<os:featureMember>
		<road:RoadNode gml:id="id657D6EB9-A9B2-4A40-B1F8-62B9F4BA0211">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:geometry>
				<gml:Point gml:id="id657D6EB9-A9B2-4A40-B1F8-62B9F4BA0211-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:pos>98983.03 912042.5</gml:pos>
				</gml:Point>
			</net:geometry>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<tn-ro:formOfRoadNode codeSpace="http://inspire.ec.europa.eu/codelist/FormOfRoadNodeValue">road end</tn-ro:formOfRoadNode>
		</road:RoadNode>
	</os:featureMember>
	<os:featureMember>
		<road:RoadNode gml:id="idB1EDF3A4-DAC6-41D1-B200-1E7C2E6BBB52">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:geometry>
				<gml:Point gml:id="idB1EDF3A4-DAC6-41D1-B200-1E7C2E6BBB52-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:pos>99169.6 912068.49</gml:pos>
				</gml:Point>
			</net:geometry>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<tn-ro:formOfRoadNode codeSpace="http://inspire.ec.europa.eu/codelist/FormOfRoadNodeValue">junction</tn-ro:formOfRoadNode>
		</road:RoadNode>
	</os:featureMember>
	<os:featureMember>
		<road:RoadNode gml:id="idA6B49C79-2926-4442-9CAF-31D5D01AACC2">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:geometry>
				<gml:Point gml:id="idA6B49C79-2926-4442-9CAF-31D5D01AACC2-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:pos>99252.27 926148.29</gml:pos>
				</gml:Point>
			</net:geometry>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<tn-ro:formOfRoadNode codeSpace="http://inspire.ec.europa.eu/codelist/FormOfRoadNodeValue">junction</tn-ro:formOfRoadNode>
		</road:RoadNode>
	</os:featureMember>
	<os:featureMember>
		<road:RoadNode gml:id="idFF63D222-6E37-4191-A914-B8FCCF8C2294">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:geometry>
				<gml:Point gml:id="idFF63D222-6E37-4191-A914-B8FCCF8C2294-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:pos>99345.4 923426.37</gml:pos>
				</gml:Point>
			</net:geometry>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<tn-ro:formOfRoadNode codeSpace="http://inspire.ec.europa.eu/codelist/FormOfRoadNodeValue">road end</tn-ro:formOfRoadNode>
		</road:RoadNode>
	</os:featureMember>
	<os:featureMember>
		<road:RoadNode gml:id="id62F323B2-7782-454B-88CC-94105DF52097">
			<net:beginLifespanVersion xsi:nil="true" nilReason="inapplicable"/>
			<net:inNetwork xsi:nil="true"/>
			<net:geometry>
				<gml:Point gml:id="id62F323B2-7782-454B-88CC-94105DF52097-0" srsName="urn:ogc:def:crs:EPSG::27700" srsDimension="2">
					<gml:pos>9299.76 900160.53</gml:pos>
				</gml:Point>
			</net:geometry>
			<tn:validFrom xsi:nil="true" nilReason="inapplicable"/>
			<tn-ro:formOfRoadNode codeSpace="http://inspire.ec.europa.eu/codelist/FormOfRoadNodeValue">road end</tn-ro:formOfRoadNode>
		</road:RoadNode>
	</os:featureMember>
</os:FeatureCollection>'
;

;WITH XMLNAMESPACES (
	 'urn:x-inspire:specification:gmlas:RoadTransportNetwork:3.0'	 AS [tn-ro]
	,'http://www.isotc211.org/2005/gmd'								 AS gmd
	,'urn:x-inspire:specification:gmlas:CommonTransportElements:3.0' AS tn
	,'http://www.w3.org/1999/xlink'									 AS xlink
	,'http://namespaces.os.uk/mastermap/highwayNetwork/1.0'			 AS highway
	,'urn:x-inspire:specification:gmlas:Network:3.2'				 AS net
	,'http://www.isotc211.org/2005/gts'								 AS gts
	,'urn:x-inspire:specification:gmlas:BaseTypes:3.2'				 AS base
	,'http://namespaces.os.uk/product/1.0'							 AS os
	,'http://www.isotc211.org/2005/gsr'								 AS gsr
	,'http://www.opengis.net/gml/3.3/xbt'							 AS gmlxbt
	,'http://www.isotc211.org/2005/gco'								 AS gco
	,'http://namespaces.os.uk/Open/Roads/1.0'						 AS road
	,'http://www.opengis.net/gml/3.2'								 AS gml
	,'urn:x-inspire:specification:gmlas:GeographicalNames:3.0'		 AS gn
	,'http://www.w3.org/2001/XMLSchema-instance'					 AS xsi
	,'http://www.isotc211.org/2005/gss'								 AS gss
)
SELECT
	  e.E.value('/gml:lowerCorner', 'nvarchar(100)')
	 ,e.E.query('.')
FROM @GeeEmmEll.nodes('os:FeatureCollection') a(FC)
OUTER APPLY a.FC.nodes('gml:boundedBy') b(BB)
OUTER APPLY a.FC.nodes('os:metadata') c(FM)
OUTER APPLY a.FC.nodes('os:featureMember') d(FM)
OUTER APPLY b.BB.nodes('gml:Envelope') e(E)
;

--LINESTRING (98660.44 926076.38,98958.12 926124.47,98980 926128,99010 926138,99062 926141,99105 926151,99139 926150,99200 926163,99238 926148,99252.27 926148.29)
--LINESTRING (98956.87 912358.01,98953.37 912330.68,98952 912320,98960 912306)
--LINESTRING (98960 912306,99006 912285,99072.43 912197.09,99143.85 912102.57,99169.6 912068.49)
--LINESTRING (99169.6 912068.49,99076.32 912055.49,98983.03 912042.5)
--LINESTRING (99345.4 923426.37,99351.0 923444.71,99349 923503,99339 923538,99312 923592,99293.18 923670.86,99291.21 923679.13,99291 923680,99287.96 923684.56,99283 923692,99240 923717,99214 923742,99213.46 923743.71,99191.4 923812.88,99215 923860,99231 923923,99200 924017,99203 924031,99220 924050,99221 924066,99209 924084,99196 924102,99203 924177,99246 924209,99248 924223,99147 924263,99131 924284,99127 924301,99134 924332,99162 924375,99185 924444,99183 924490,99163 924559,99184.29 924694.36,99191 924737,99184 924819,99155 924881,99145 924949,99107.5 925021.83,99102.84 925043.14,99102.09 925059.95,99096.21 925191.63,99101.07 925440.89,99162.12 925614.44,99176.07 925672.94,99184.37 925684.37,99186.81 925687.72,99195 925699,99230.22 925845.74,99252.27 926148.29)
--LINESTRING (99169.6 912068.49,99209.0 912063.04,99248.4 912057.59,99322 912046,99348 912006,99498 911820,99567 911755,99610 911676,99670 911538,99678 911482,99700 911403,99755 911342,99802 911303,99878 911184,99930 911115,100000 910998,100018 910945,100049 910905,100160 910811,100217 910749,100349.6 910644.67,100353 910642,100367 910625,100393 910569,100440 910529,100484 910507,100604 910470,100668 910436,100746 910416,100816 910373,100891 910337,101120 910246,101177.38 910232.43,101224 910216,101327 910160,101415 910060,101547 909941,101729 909808,101813 909718,101854 909658)
--LINESTRING (100061 929405,100046 929379,100032 929298,100000 929262,99877 929160,99831 929067,99818 929023,99818 928975,99846 928781,99890 928698,99900 928662,99901 928626,99894 928605,99874 928570,99830 928517,99631.1 928321.37,99479.99 928123.85,99401.39 928009.09,99381.69 927954.46,99378.55 927900.37,99368.79 927732.36,99359.34 927679.35,99324 927591,99208.03 927367.27,99226.31 927057.13,99268.35 926628.98,99270.08 926400.08,99252.27 926148.29)
--LINESTRING (9242 899133,9196 899166,9149 899232,9133 899279,9123 899357,9128 899364,9161 899369,9158 899397,9190 899414,9247.45 899602.52,9254 899624,9263 899729,9264 899854,9305 899946,9297 900000,9291 900079,9299.76 900160.53)

DECLARE @g geometry = geometry::STGeomFromText('LINESTRING (99169.6 912068.49,99076.32 912055.49,98983.03 912042.5)', 4277);

SELECT @g;






--DECLARE @Geo xml =
--'<gml:LineString>
--	<gml:posList>98660.44 926076.38 98958.12 926124.47 98980 926128 99010 926138 99062 926141 99105 926151 99139 926150 99200 926163 99238 926148 99252.27 926148.29</gml:posList>
--</gml:LineString>'
--;

--;WITH XMLNAMESPACES (
--	'http://www.opengis.net/gml/3.2' AS gml
--)
--SELECT Hello = geography::GeomFromGml(@Geo, 4277)
--;









