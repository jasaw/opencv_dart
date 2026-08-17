import 'package:dartcv4/dartcv.dart' as cv;
import 'package:test/test.dart';

void main() {
  test('cv.CharucoDetectorParameters', () {
    final params = cv.CharucoDetectorParameters.empty();
    final cameraMatrix = cv.Mat.from2DList(
      [
        [1000.0, 0.0, 320.0],
        [0.0, 1000.0, 240.0],
        [0.0, 0.0, 1.0],
      ],
      cv.MatType.CV_64FC1,
    );
    final distCoeffs = cv.Mat.zeros(1, 5, cv.MatType.CV_64FC1);

    params.cameraMatrix = cameraMatrix;
    params.distCoeffs = distCoeffs;
    params.minMarkers = 3;
    params.tryRefineMarkers = true;
    params.checkMarkers = false;

    expect(params.cameraMatrix.rows, 3);
    expect(params.distCoeffs.total, 5);
    expect(params.minMarkers, 3);
    expect(params.tryRefineMarkers, true);
    expect(params.checkMarkers, false);

    params.dispose();
    cameraMatrix.dispose();
    distCoeffs.dispose();
  });

  test('cv.ArucoRefineParameters', () {
    final params = cv.ArucoRefineParameters.create(
      minRepDistance: 11.0,
      errorCorrectionRate: 2.0,
      checkAllOrders: false,
    );

    expect(params.minRepDistance, closeTo(11.0, 1e-6));
    expect(params.errorCorrectionRate, closeTo(2.0, 1e-6));
    expect(params.checkAllOrders, false);

    params.dispose();
  });

  test('cv.CharucoDetector.detectBoard and helpers', () {
    final dict = cv.ArucoDictionary.predefined(cv.PredefinedDictionaryType.DICT_6X6_250);
    final board = cv.CharucoBoard.create((5, 7), 0.04, 0.02, dict);
    final image = board.generateImage((800, 1000), marginSize: 24);
    final params = cv.CharucoDetectorParameters.empty()
      ..tryRefineMarkers = true
      ..minMarkers = 2;
    final refineParams = cv.ArucoRefineParameters.create();
    final detectorParams = cv.ArucoDetectorParameters.empty();
    final detector = cv.CharucoDetector.create(
      board,
      params,
      detectorParameters: detectorParams,
      refineParameters: refineParams,
    );
    final defaultDetector = cv.CharucoDetector.fromBoard(board);

    final (charucoCorners, charucoIds, markerCorners, markerIds) = detector.detectBoard(image);
    expect(charucoCorners.length, greaterThan(3));
    expect(charucoIds.length, greaterThan(3));
    expect(markerCorners.length, greaterThan(0));
    expect(markerIds.length, greaterThan(0));
    final (defaultCorners, defaultIds, _, _) = defaultDetector.detectBoard(image);
    expect(defaultCorners.length, greaterThan(3));
    expect(defaultIds.length, greaterThan(3));

    final detectorBoard = detector.board;
    final detectorCharucoParams = detector.charucoParameters;
    final detectorRefineParams = detector.refineParameters;
    final detectorDetectorParams = detector.detectorParameters;
    expect(detectorBoard.chessboardSize.width, board.chessboardSize.width);
    expect(detectorCharucoParams.minMarkers, 2);
    expect(detectorRefineParams.checkAllOrders, true);
    expect(detectorDetectorParams.adaptiveThreshWinSizeMin, greaterThan(0));

    final (objPoints, imgPoints) = board.matchImagePoints(charucoCorners, charucoIds);
    expect(objPoints.isEmpty, false);
    expect(imgPoints.isEmpty, false);

    final drawn = cv.cvtColor(image, cv.COLOR_GRAY2BGR);
    final originalBgr = cv.cvtColor(image, cv.COLOR_GRAY2BGR);
    cv.drawDetectedCornersCharuco(drawn, charucoCorners, charucoIds);
    final diff = cv.absDiff(drawn, originalBgr);
    final diffGray = cv.cvtColor(diff, cv.COLOR_BGR2GRAY);
    expect(cv.countNonZero(diffGray), greaterThan(0));

    final cameraMatrix = cv.Mat.from2DList(
      [
        [1000.0, 0.0, image.cols / 2.0],
        [0.0, 1000.0, image.rows / 2.0],
        [0.0, 0.0, 1.0],
      ],
      cv.MatType.CV_64FC1,
    );
    final distCoeffs = cv.Mat.zeros(1, 5, cv.MatType.CV_64FC1);
    final (ok, rvec, tvec) = cv.estimatePoseCharucoBoard(
      charucoCorners,
      charucoIds,
      board,
      cameraMatrix,
      distCoeffs,
    );
    expect(ok, true);
    expect(rvec.isEmpty, false);
    expect(tvec.isEmpty, false);

    detector.dispose();
    defaultDetector.dispose();
    detectorParams.dispose();
    refineParams.dispose();
    params.dispose();
    detectorBoard.dispose();
    detectorCharucoParams.dispose();
    detectorRefineParams.dispose();
    detectorDetectorParams.dispose();
    rvec.dispose();
    tvec.dispose();
    distCoeffs.dispose();
    cameraMatrix.dispose();
    diffGray.dispose();
    diff.dispose();
    originalBgr.dispose();
    drawn.dispose();
    objPoints.dispose();
    imgPoints.dispose();
    image.dispose();
    board.dispose();
    dict.dispose();
  });
}
