@IsTest
private class P2P_CalloutServiceTest {

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            String ep = req.getEndpoint();
            if (ep.contains('beststories')) {
                res.setBody('[111,222,333]');
                res.setStatusCode(200);
                res.setStatus('OK');
            } else if (ep.contains('topstories')) {
                res.setBody('[444,555,666]');
                res.setStatusCode(200);
                res.setStatus('OK');
            } else if (ep.contains('newstories')) {
                res.setBody('[777,888]');
                res.setStatusCode(200);
                res.setStatus('OK');
            } else if (ep.contains('/item/')) {
                // HN item JSON with numbers – sanitized to ResponseWrapper String fields
                res.setBody('{"by":"alice","id":123,"time":1700000000,"type":"story","title":"Mock Title","url":"https://example.com","score":99,"descendants":5,"kids":[1,2]}');
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

    private class FailureMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setStatus('Internal Server Error');
            res.setBody('error');
            return res;
        }
    }

    @IsTest
    static void testGetHNBestStoryIdsSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        List<String> ids = P2P_CalloutService.getHNBestStoryIds(false);
        Test.stopTest();
        Assert.areEqual(3, ids.size(), 'Should return 3 ids');
        Assert.areEqual('111', ids[0]);
    }

    @IsTest
    static void testGetHNTopStoryIdsSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        List<String> ids = P2P_CalloutService.getHNTopStoryIds(false);
        Test.stopTest();
        Assert.areEqual(3, ids.size());
        Assert.areEqual('444', ids[0]);
    }

    @IsTest
    static void testGetHNNewStoryIdsSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        List<String> ids = P2P_CalloutService.getHNNewStoryIds(false);
        Test.stopTest();
        Assert.areEqual(2, ids.size());
    }

    @IsTest
    static void testGetHNItemAsWrapperSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        ResponseWrapper rw = P2P_CalloutService.getHNItemAsWrapper('123', false);
        Test.stopTest();
        Assert.areNotEqual(null, rw, 'Wrapper not null');
        Assert.areEqual('123', rw.ItemId);
        Assert.areEqual('alice', rw.postedBy);
        Assert.areEqual('Mock Title', rw.title);
        Assert.areEqual('https://example.com', rw.url);
    }

    @IsTest
    static void testExecuteSuccess() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNBestStories();
        Test.startTest();
        P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
        Test.stopTest();
        Assert.isTrue(res.isSuccess);
        Assert.areEqual(200, res.statusCode);
    }

    @IsTest
    static void testExecuteFailureReturnsErrorWrapper() {
        Test.setMock(HttpCalloutMock.class, new FailureMock());
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNBestStories();
        Test.startTest();
        P2P_HttpResponseWrapper res = P2P_CalloutService.execute(w);
        Test.stopTest();
        Assert.isFalse(res.isSuccess);
        Assert.areEqual(500, res.statusCode);
    }

    @IsTest
    static void testExecuteOrThrowThrowsOnFailure() {
        Test.setMock(HttpCalloutMock.class, new FailureMock());
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNBestStories();
        Test.startTest();
        try {
            P2P_CalloutService.executeOrThrow(w);
            Assert.fail('Should throw');
        } catch (P2P_CalloutService.P2P_CalloutException e) {
            Assert.isTrue(e.getMessage().contains('500'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testDoGetViaNC() {
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        P2P_HttpResponseWrapper res = P2P_CalloutService.doGetViaNC('HN_API', '/v0/beststories.json');
        Test.stopTest();
        Assert.isTrue(res.isSuccess);
    }

    @IsTest
    static void testRequestProcessorBuildWithNC() {
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNItemViaNC('123');
        HttpRequest req = P2P_RequestProcessor.build(w);
        Assert.isTrue(req.getEndpoint().startsWith('callout:HN_API'));
        Assert.areEqual('GET', req.getMethod());
    }

    @IsTest
    static void testResponseProcessorSanitizeAndParse() {
        String json = '{"by":"bob","id":999,"time":1700000000,"type":"story","title":"T","url":"https://x"}';
        String sanitized = P2P_ResponseProcessor.sanitizeHNJson(json);
        Assert.isTrue(sanitized.contains('"postedBy"'));
        Assert.isTrue(sanitized.contains('"ItemId"'));
        ResponseWrapper rw = P2P_ResponseProcessor.deserializeHNItem(json);
        Assert.areEqual('999', rw.ItemId);
        Assert.areEqual('bob', rw.postedBy);
        List<String> myList = P2P_ResponseProcessor.parseStringList('["a","b"]');
        Assert.areEqual(2, myList.size());
    }
}
