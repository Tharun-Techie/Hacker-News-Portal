public class Global_Constants {
    public static final String HN_API = 'https://hacker-news.firebaseio.com';
    // Build full URLs from base to avoid drift
    public static final String HN_API_BestStories = HN_API + '/v0/beststories.json?print=pretty';
    public static final String HN_API_NewStories = HN_API + '/v0/newstories.json?print=pretty';
    public static final String HN_API_TopStories = HN_API + '/v0/topstories.json?print=pretty';
    public static final String HN_API_MaxItemID = HN_API + '/v0/maxitem.json?print=pretty';

    // Pagination (centralized, was hardcoded 30/12/0 in 9 places)
    public static final Integer HN_PAGE_SIZE_DEFAULT = 12;
    public static final Integer HN_PAGE_SIZE_MAX = 30;
    public static final Integer HN_PAGE_SIZE_MIN = 1;
    public static final Integer HN_OFFSET_DEFAULT = 0;

    // Date formatting (was hardcoded 'yyyy-MM-dd HH:mm' x9)
    public static final String HN_DATE_FORMAT = 'yyyy-MM-dd HH:mm';
}