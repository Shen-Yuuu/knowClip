import { describe, beforeAll, beforeEach, afterEach, afterAll, it, expect } from '@ohos/hypium';
import { ShareDataParser } from '../main/ets/services/ShareDataParser';

export default function localUnitTest() {
  describe('localUnitTest', () => {
    // Defines a test suite. Two parameters are supported: test suite name and test suite function.
    beforeAll(() => {
      // Presets an action, which is performed only once before all test cases of the test suite start.
      // This API supports only one parameter: preset action function.
    });
    beforeEach(() => {
      // Presets an action, which is performed before each unit test case starts.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: preset action function.
    });
    afterEach(() => {
      // Presets a clear action, which is performed after each unit test case ends.
      // The number of execution times is the same as the number of test cases defined by **it**.
      // This API supports only one parameter: clear action function.
    });
    afterAll(() => {
      // Presets a clear action, which is performed after all test cases of the test suite end.
      // This API supports only one parameter: clear action function.
    });
    it('assertContain', 0, () => {
      // Defines a test case. This API supports three parameters: test case name, filter parameter, and test case function.
      let a = 'abc';
      let b = 'b';
      // Defines a variety of assertion methods, which are used to declare expected boolean conditions.
      expect(a).assertContain(b);
      expect(a).assertEqual(a);
    });

    it('parseImageFromRecordUri', 0, () => {
      const parser = new ShareDataParser();
      const result = parser.parse([
        { utd: 'general.jpeg', uri: 'file://gallery/a.jpg' }
      ]);
      expect(result.images.length).assertEqual(1);
      expect(result.images[0]).assertEqual('file://gallery/a.jpg');
    });

    it('parseImageFromRecordContent', 0, () => {
      const parser = new ShareDataParser();
      const result = parser.parse([
        { utd: 'general.jpeg', content: 'file://gallery/b.jpg' }
      ]);
      expect(result.images.length).assertEqual(1);
      expect(result.images[0]).assertEqual('file://gallery/b.jpg');
      expect(result.text).assertEqual(null);
    });

    it('parseTextAndUrl', 0, () => {
      const parser = new ShareDataParser();
      const result = parser.parse([
        { utd: 'general.plain-text', content: '参考 https://example.com/a' }
      ]);
      expect(result.text).assertEqual('参考 https://example.com/a');
      expect(result.url).assertEqual('https://example.com/a');
    });

    it('useWantUriAsEmptyShareFallback', 0, () => {
      const parser = new ShareDataParser();
      const result = parser.parse([], 'file://gallery/fallback.jpg');
      expect(result.images.length).assertEqual(1);
      expect(result.images[0]).assertEqual('file://gallery/fallback.jpg');
    });
  });
}
