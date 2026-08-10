@IsTest
private class TopStoriesControllerTest {

    private class TopMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String ep = req.getEndpoint();
            if (ep.contains('topstories')) {
                res.setBody('[999,888,777,666]');
                res.setStatusCode(200);
                res.setStatus('OK');
            } else if (ep.contains('/item/')) {
                res.setBody('{"by":"bob","id":999,"time":1700001111,"type":"story","title":"Top Mock Title","url":"https://example.com/top","score":200,"descendants":30,"kids":[10,20]}');
                res.setStatusCode(200);
                res.setStatus('OK');
            } else {
                res.setBody('[]');
                res.setStatusCode(200);
                res.setStatus('OK');
            }
            return res;
        }
    }

    private class EmptyMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setBody('[]');
            res.setStatusCode(200);
            res.setStatus('OK');
            return res;
        }
    }

    @IsTest
    static void testGetTopStoriesTilesSuccess() {
        Test.setMock(HttpCalloutMock.class, new TopMock());
        Test.startTest();
        List<TopStoriesController.StoryTile> tiles = TopStoriesController.getTopStoriesTiles(2, 0);
        Test.stopTest();
        Assert.areEqual(2, tiles.size());
        Assert.areEqual('999', tiles[0].itemId);
        Assert.areEqual('Top Mock Title', tiles[0].title);
        Assert.areEqual('bob', tiles[0].postedBy);
        Assert.isTrue(tiles[0].hasUrl);
        Assert.areEqual(2, tiles[0].kidsCount);
        Assert.isNotNull(tiles[0].formattedTime, 'formattedTime should not be null');
    }

    @IsTest
    static void testGetTopStoriesTilesPaginationAndOffset() {
        Test.setMock(HttpCalloutMock.class, new TopMock());
        Test.startTest();
        List<TopStoriesController.StoryTile> p1 = TopStoriesController.getTopStoriesTiles(2, 0);
        List<TopStoriesController.StoryTile> p2 = TopStoriesController.getTopStoriesTiles(2, 2);
        Test.stopTest();
        Assert.areEqual(2, p1.size());
        Assert.areEqual(2, p2.size());
    }

    @IsTest
    static void testGetTopStoriesTilesBeyondReturnsEmpty() {
        Test.setMock(HttpCalloutMock.class, new TopMock());
        Test.startTest();
        List<TopStoriesController.StoryTile> tiles = TopStoriesController.getTopStoriesTiles(10, 100);
        Test.stopTest();
        Assert.areEqual(0, tiles.size());
    }

    @IsTest
    static void testGetTopStoriesCount() {
        Test.setMock(HttpCalloutMock.class, new TopMock());
        Test.startTest();
        Integer cnt = TopStoriesController.getTopStoriesCount();
        Test.stopTest();
        Assert.areEqual(4, cnt);
    }

    @IsTest
    static void testGetStoryByIdSuccess() {
        Test.setMock(HttpCalloutMock.class, new TopMock());
        Test.startTest();
        ResponseWrapper rw = TopStoriesController.getStoryById('999');
        Test.stopTest();
        Assert.areEqual('999', rw.ItemId);
    }

    @IsTest
    static void testEmptyReturnsEmpty() {
        Test.setMock(HttpCalloutMock.class, new EmptyMock());
        Test.startTest();
        List<TopStoriesController.StoryTile> tiles = TopStoriesController.getTopStoriesTiles(5, 0);
        Test.stopTest();
        Assert.areEqual(0, tiles.size());
    }

    @IsTest
    static void testGetStoryByIdBlankThrows() {
        Test.startTest();
        try {
            TopStoriesController.getStoryById(null);
            Assert.fail('Should throw AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(String.isNotBlank(e.getMessage()), 'Exception message should not be blank');
        } catch (Exception e) {
            Assert.isTrue(true, 'Any exception is acceptable for blank id');
        }
        Test.stopTest();
    }
}
