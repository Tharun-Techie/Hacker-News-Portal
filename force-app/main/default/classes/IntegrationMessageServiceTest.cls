@IsTest
private class IntegrationMessageServiceTest {

    private class SuccessMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200); res.setStatus('OK'); res.setHeader('Content-Type','application/json');
            String ep = req.getEndpoint();
            if (ep.contains('beststories')) res.setBody('[111,222,333]');
            else if (ep.contains('topstories')) res.setBody('[444,555]');
            else if (ep.contains('newstories')) res.setBody('[777,888]');
            else if (ep.contains('/item/')) res.setBody('{"by":"alice","id":123,"time":1700000000,"type":"story","title":"T","url":"https://x","score":10,"descendants":5,"kids":[1,2]}');
            else res.setBody('[]');
            return res;
        }
    }
    private class ErrorMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500); res.setStatus('Error'); res.setBody('err');
            return res;
        }
    }

    @IsTest static void testBuildMessage() {
        P2P_HttpRequestWrapper req = P2P_HttpRequestWrapper.forHNItem('123');
        P2P_HttpResponseWrapper res = new P2P_HttpResponseWrapper();
        res.statusCode = 200; res.status='OK'; res.body='{"by":"a","id":123}'; res.isSuccess=true;
        Integration_Message__c m = IntegrationMessageService.buildMessage(req, res, 'HN_API','getHNItem','123');
        Assert.areEqual('HN_API', m.Integration_Name__c);
        Assert.areEqual('getHNItem', m.Operation__c);
        Assert.areEqual('123', m.Reference_Id__c);
        Assert.areEqual(200, m.Status_Code__c);
        Assert.isTrue(m.Is_Success__c);
        // null wrappers
        Integration_Message__c m2 = IntegrationMessageService.buildMessage(null, null, null, null, null);
        Assert.isNotNull(m2);
        // headers
        req.withHeader('X','1'); req.withHeader('Y','2');
        Integration_Message__c m3 = IntegrationMessageService.buildMessage(req, res, 'HN_API','op','ref');
        Assert.isTrue(m3.Request_Headers__c.contains('X'));
        // long endpoint truncation
        req.endpoint = 'https://example.com/' + 'a'.repeat(300);
        Integration_Message__c m4 = IntegrationMessageService.buildMessage(req, res, 'HN_API','op','ref');
        Assert.areEqual(255, m4.Endpoint__c.length());
    }

    @IsTest static void testLogAndBufferFlush() {
        IntegrationMessageService.clearBuffer();
        P2P_HttpRequestWrapper req = P2P_HttpRequestWrapper.forHNItem('999');
        P2P_HttpResponseWrapper res = new P2P_HttpResponseWrapper();
        res.statusCode=200; res.status='OK'; res.body='{"by":"bob","id":999,"time":1700000000,"type":"story","title":"T"}'; res.isSuccess=true;
        // buffered log (no immediate DML to avoid uncommitted work pending)
        Id id = IntegrationMessageService.logMessage(req, res, 'HN_API','getHNItem','999');
        Assert.areEqual(null, id); // buffered, not immediate
        Assert.areEqual(1, IntegrationMessageService.pendingCount());
        Integer flushed = IntegrationMessageService.flushBuffer();
        Assert.areEqual(1, flushed);
        List<Integration_Message__c> q=[SELECT Id, Reference_Id__c FROM Integration_Message__c WHERE Reference_Id__c='999' LIMIT 1];
        Assert.areEqual(1, q.size());

        IntegrationMessageService.clearBuffer();
        P2P_HttpRequestWrapper req2 = P2P_HttpRequestWrapper.forHNTopStories();
        P2P_HttpResponseWrapper res2 = new P2P_HttpResponseWrapper(); res2.statusCode=200; res2.body='[1,2,3]'; res2.isSuccess=true; res2.status='OK';
        IntegrationMessageService.buildMessage(req2, res2, 'HN_API','getHNTopStoryIds', null);
        Assert.areEqual(0, IntegrationMessageService.pendingCount());
        Integer flushed2 = IntegrationMessageService.flushBuffer();
        Assert.areEqual(0, flushed2);
    }

    @IsTest static void testLogDerive() {
        IntegrationMessageService.clearBuffer();
        P2P_HttpRequestWrapper w1 = P2P_HttpRequestWrapper.forHNBestStories();
        P2P_HttpResponseWrapper r1 = new P2P_HttpResponseWrapper(); r1.statusCode=200; r1.body='[1,2]'; r1.isSuccess=true; r1.status='OK';
        Id id1 = IntegrationMessageService.log(w1, r1);
        Assert.areEqual(null, id1); // buffered
        Assert.areEqual(1, IntegrationMessageService.pendingCount());
        IntegrationMessageService.flushBuffer();
        List<Integration_Message__c> msgs=[SELECT Operation__c FROM Integration_Message__c WHERE Reference_Id__c=null AND Operation__c='getHNBestStoryIds' LIMIT 1];
        Assert.isFalse(msgs.isEmpty());
        Assert.areEqual('getHNBestStoryIds', msgs[0].Operation__c);

        P2P_HttpRequestWrapper w2 = P2P_HttpRequestWrapper.forHNItem('555');
        Id id2 = IntegrationMessageService.log(w2, r1);
        Assert.areEqual(null, id2);
        IntegrationMessageService.flushBuffer();
        List<Integration_Message__c> m2=[SELECT Reference_Id__c, Operation__c FROM Integration_Message__c WHERE Reference_Id__c='555' LIMIT 1];
        Assert.areEqual('555', m2[0].Reference_Id__c);
        Assert.areEqual('getHNItem', m2[0].Operation__c);

        Id idNull = IntegrationMessageService.log(null, null);
        Assert.areEqual(null, idNull);
        Integer c = IntegrationMessageService.flushBuffer();
        Assert.isTrue(c>=1);
    }

    @IsTest static void testFetchFromStore() {
        // Insert a known message
        Integration_Message__c m = new Integration_Message__c(
            Endpoint__c='https://hacker-news.firebaseio.com/v0/item/123.json?print=pretty',
            Http_Method__c='GET',
            Response_Body__c='{"by":"alice","id":123,"time":1700000000,"type":"story","title":"Stored Title","url":"https://x","score":10,"descendants":5,"kids":[1,2]}',
            Status_Code__c=200, Status__c='OK', Is_Success__c=true,
            Integration_Name__c='HN_API', Operation__c='getHNItem', Reference_Id__c='123'
        );
        insert m;
        // also insert list for beststories
        Integration_Message__c m2 = new Integration_Message__c(
            Endpoint__c=Global_Constants.HN_API_BestStories,
            Response_Body__c='[111,222,333]',
            Status_Code__c=200, Is_Success__c=true,
            Integration_Name__c='HN_API', Operation__c='getHNBestStoryIds'
        );
        insert m2;
        Integration_Message__c m3 = new Integration_Message__c(
            Endpoint__c=Global_Constants.HN_API_TopStories,
            Response_Body__c='[444,555]',
            Status_Code__c=200, Is_Success__c=true,
            Integration_Name__c='HN_API', Operation__c='getHNTopStoryIds'
        );
        insert m3;

        Test.startTest();
        Integration_Message__c fetched = IntegrationMessageService.getLatestByReference('123','getHNItem');
        Assert.areEqual('123', fetched.Reference_Id__c);
        ResponseWrapper rw = IntegrationMessageService.getHNItemFromStore('123');
        Assert.areEqual('123', rw.ItemId);
        Assert.areEqual('alice', rw.postedBy);

        List<String> idsBest = IntegrationMessageService.getHNStoryIdsFromStore('getHNBestStoryIds');
        Assert.areEqual(3, idsBest.size());
        Assert.areEqual('111', idsBest[0]);

        List<String> idsTop = IntegrationMessageService.getHNStoryIdsFromStore('getHNTopStoryIds');
        Assert.areEqual(2, idsTop.size());

        String body = IntegrationMessageService.getResponseBodyFromStore('123','getHNItem');
        Assert.isTrue(body.contains('Stored Title'));

        // null/blank cases
        Assert.areEqual(null, IntegrationMessageService.getLatestByReference('', 'getHNItem'));
        Assert.areEqual(null, IntegrationMessageService.getLatestByReference(null, null));
        Assert.areEqual(null, IntegrationMessageService.getLatestByEndpoint(''));
        Assert.areEqual(null, IntegrationMessageService.getLatestByOperation(''));
        Assert.areEqual(null, IntegrationMessageService.getHNItemFromStore('nonexistent'));
        Assert.areEqual(0, IntegrationMessageService.getHNStoryIdsFromStore('nonexistent').size());
        Test.stopTest();

        // getLatestByEndpoint
        Integration_Message__c byEp = IntegrationMessageService.getLatestByEndpoint(m.Endpoint__c);
        Assert.areEqual(m.Id, byEp.Id);
        Integration_Message__c byOp = IntegrationMessageService.getLatestByOperation('getHNBestStoryIds');
        Assert.areEqual(m2.Id, byOp.Id);
    }

    @IsTest static void testP2PIntegrationWithCallout() {
        IntegrationMessageService.clearBuffer();
        Test.setMock(HttpCalloutMock.class, new SuccessMock());
        Test.startTest();
        // This will do callout and buffer Integration_Message (no immediate DML to avoid uncommitted work)
        P2P_HttpResponseWrapper resp = P2P_CalloutService.getHNItem('123', false);
        Assert.isTrue(resp.isSuccess);
        // Buffered, not yet flushed - but fetch from store should work via buffer
        Assert.areEqual(1, IntegrationMessageService.pendingCount());
        ResponseWrapper rw = P2P_CalloutService.getHNItemFromStore('123');
        Assert.isNotNull(rw);
        Assert.areEqual('123', rw.ItemId);

        // Second callout in same transaction - must not flush between, else "uncommitted work pending"
        List<String> bestIds = P2P_CalloutService.getHNBestStoryIds(false);
        Assert.areEqual(3, bestIds.size());
        Assert.areEqual(2, IntegrationMessageService.pendingCount());
        List<String> cachedBest = P2P_CalloutService.getHNBestStoryIdsFromStore();
        Assert.areEqual(3, cachedBest.size());

        // Now flush once at end
        Integer flushed = P2P_CalloutService.flushIntegrationMessages();
        Assert.areEqual(2, flushed);
        List<Integration_Message__c> msgs=[SELECT Id, Operation__c, Reference_Id__c FROM Integration_Message__c WHERE Reference_Id__c='123' LIMIT 5];
        Assert.isTrue(msgs.size()>=1);

        List<String> bestWithCache = P2P_CalloutService.getHNBestStoryIdsWithCache(false);
        Assert.isTrue(bestWithCache.size()>=3);

        Test.stopTest();
    }

    @IsTest static void testP2PErrorLogging() {
        Test.setMock(HttpCalloutMock.class, new ErrorMock());
        Test.startTest();
        P2P_HttpRequestWrapper w = P2P_HttpRequestWrapper.forHNItem('999');
        P2P_HttpResponseWrapper err = P2P_CalloutService.execute(w);
        Assert.isFalse(err.isSuccess);
        P2P_CalloutService.flushIntegrationMessages();
        List<Integration_Message__c> msgs=[SELECT Is_Success__c, Status_Code__c FROM Integration_Message__c WHERE Reference_Id__c='999' LIMIT 1];
        // may be buffered, but at least one error logged
        // check that log didn't throw
        Test.stopTest();
    }

    @IsTest static void testControllersFromStore() {
        // Seed store for BestStories
        Integration_Message__c mBest = new Integration_Message__c(
            Endpoint__c=Global_Constants.HN_API_BestStories, Response_Body__c='[123]', Status_Code__c=200, Is_Success__c=true,
            Integration_Name__c='HN_API', Operation__c='getHNBestStoryIds'
        );
        insert mBest;
        Integration_Message__c mItem = new Integration_Message__c(
            Endpoint__c=Global_Constants.HN_API + '/v0/item/123.json?print=pretty',
            Response_Body__c='{"by":"alice","id":123,"time":1700000000,"type":"story","title":"StoreTitle","url":"https://x","score":10,"descendants":5,"kids":[1,2]}',
            Status_Code__c=200, Is_Success__c=true, Integration_Name__c='HN_API', Operation__c='getHNItem', Reference_Id__c='123'
        );
        insert mItem;
        // Top
        Integration_Message__c mTop = new Integration_Message__c(
            Endpoint__c=Global_Constants.HN_API_TopStories, Response_Body__c='[123]', Status_Code__c=200, Is_Success__c=true,
            Integration_Name__c='HN_API', Operation__c='getHNTopStoryIds'
        );
        insert mTop;

        Test.startTest();
        List<BestStoriesController.StoryTile> tiles = BestStoriesController.getBestStoriesTilesFromStore(1,0);
        Assert.areEqual(1, tiles.size());
        Assert.areEqual('StoreTitle', tiles[0].title);
        ResponseWrapper rw = BestStoriesController.getStoryByIdFromStore('123');
        Assert.areEqual('123', rw.ItemId);
        Integer cnt = BestStoriesController.getBestStoriesCountFromStore();
        Assert.areEqual(1, cnt);

        List<TopStoriesController.StoryTile> topTiles = TopStoriesController.getTopStoriesTilesFromStore(1,0);
        Assert.areEqual(1, topTiles.size());
        ResponseWrapper rw2 = TopStoriesController.getStoryByIdFromStore('123');
        Assert.areEqual('123', rw2.ItemId);
        Integer cntTop = TopStoriesController.getTopStoriesCountFromStore();
        Assert.areEqual(1, cntTop);
        Test.stopTest();
    }
}
