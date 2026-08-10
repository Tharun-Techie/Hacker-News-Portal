@IsTest
private class BestStoriesControllerTest {

    private class BestMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String ep = req.getEndpoint();
            if (ep.contains('beststories')) {
                res.setBody('[111,222,333,444,555]');
                res.setStatusCode(200);
                res.setStatus('OK');
            } else if (ep.contains('/item/')) {
                res.setBody('{"by":"alice","id":111,"time":1700000000,"type":"story","title":"Best Mock Title","url":"https://example.com/best","score":150,"descendants":20,"kids":[1,2,3]}');
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
    static void testGetBestStoriesTilesSuccess() {
        Test.setMock(HttpCalloutMock.class, new BestMock());
        Test.startTest();
        List<BestStoriesController.StoryTile> tiles = BestStoriesController.getBestStoriesTiles(2, 0);
        Test.stopTest();
        Assert.areEqual(2, tiles.size(), 'Should return 2 tiles');
        Assert.areEqual('111', tiles[0].itemId);
        Assert.areEqual('Best Mock Title', tiles[0].title);
        Assert.areEqual('alice', tiles[0].postedBy);
        Assert.isTrue(tiles[0].hasUrl);
        Assert.areEqual(3, tiles[0].kidsCount);
        Assert.isNotNull(tiles[0].formattedTime, 'formattedTime should not be null');
    }

    @IsTest
    static void testGetBestStoriesTilesPagination() {
        Test.setMock(HttpCalloutMock.class, new BestMock());
        Test.startTest();
        List<BestStoriesController.StoryTile> page1 = BestStoriesController.getBestStoriesTiles(2, 0);
        List<BestStoriesController.StoryTile> page2 = BestStoriesController.getBestStoriesTiles(2, 2);
        Test.stopTest();
        Assert.areEqual(2, page1.size());
        Assert.areEqual(2, page2.size());
    }

    @IsTest
    static void testGetBestStoriesTilesOffsetBeyondSizeReturnsEmpty() {
        Test.setMock(HttpCalloutMock.class, new BestMock());
        Test.startTest();
        List<BestStoriesController.StoryTile> tiles = BestStoriesController.getBestStoriesTiles(10, 100);
        Test.stopTest();
        Assert.areEqual(0, tiles.size());
    }

    @IsTest
    static void testGetBestStoriesCount() {
        Test.setMock(HttpCalloutMock.class, new BestMock());
        Test.startTest();
        Integer cnt = BestStoriesController.getBestStoriesCount();
        Test.stopTest();
        Assert.areEqual(5, cnt);
    }

    @IsTest
    static void testGetStoryByIdSuccess() {
        Test.setMock(HttpCalloutMock.class, new BestMock());
        Test.startTest();
        ResponseWrapper rw = BestStoriesController.getStoryById('111');
        Test.stopTest();
        Assert.areEqual('111', rw.ItemId);
    }

    @IsTest
    static void testGetStoryByIdBlankThrows() {
        Test.startTest();
        try {
            BestStoriesController.getStoryById('');
            Assert.fail('Should throw AuraHandledException');
        } catch (AuraHandledException e) {
            Assert.isTrue(String.isNotBlank(e.getMessage()), 'Exception message should not be blank');
        } catch (Exception e) {
            Assert.isTrue(true, 'Any exception is acceptable for blank id');
        }
        Test.stopTest();
    }

    @IsTest
    static void testEmptyBestStoriesReturnsEmptyTiles() {
        Test.setMock(HttpCalloutMock.class, new EmptyMock());
        Test.startTest();
        List<BestStoriesController.StoryTile> tiles = BestStoriesController.getBestStoriesTiles(5, 0);
        Test.stopTest();
        Assert.areEqual(0, tiles.size());
    }
}
