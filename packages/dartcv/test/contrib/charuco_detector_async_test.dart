import 'package:dartcv4/dartcv.dart' as cv;
import 'package:test/test.dart';

void main() {
  test('cv.CharucoDetector.detectBoardAsync', () async {
    final dict = cv.ArucoDictionary.predefined(cv.PredefinedDictionaryType.DICT_6X6_250);
    final board = cv.CharucoBoard.create((5, 7), 0.04, 0.02, dict);
    final image = board.generateImage((800, 1000), marginSize: 24);
    final params = cv.CharucoDetectorParameters.empty();
    final detector = cv.CharucoDetector.create(board, params);

    final (charucoCorners, charucoIds, markerCorners, markerIds) = await detector.detectBoardAsync(image);
    expect(charucoCorners.length, greaterThan(3));
    expect(charucoIds.length, greaterThan(3));
    expect(markerCorners.length, greaterThan(0));
    expect(markerIds.length, greaterThan(0));

    final drawn = cv.cvtColor(image, cv.COLOR_GRAY2BGR);
    await cv.drawDetectedCornersCharucoAsync(drawn, charucoCorners, charucoIds);
    final cameraMatrix = cv.Mat.from2DList(
      [
        [1000.0, 0.0, image.cols / 2.0],
        [0.0, 1000.0, image.rows / 2.0],
        [0.0, 0.0, 1.0],
      ],
      cv.MatType.CV_64FC1,
    );
    final distCoeffs = cv.Mat.zeros(1, 5, cv.MatType.CV_64FC1);
    final (ok, rvec, tvec) = await cv.estimatePoseCharucoBoardAsync(
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
    params.dispose();
    rvec.dispose();
    tvec.dispose();
    distCoeffs.dispose();
    cameraMatrix.dispose();
    drawn.dispose();
    image.dispose();
    board.dispose();
    dict.dispose();
  });
}
