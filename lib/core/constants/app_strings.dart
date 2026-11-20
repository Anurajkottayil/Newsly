/// Centralized user-facing strings for the Newsly application.
class AppStrings {
  AppStrings._();

  // Application
  static const String appName = 'Newsly';

  // Discover Screen Reference
  static const String discover = 'Discover';
  static const String discoverSubtitle = 'News from all around the world';
  static const String searchHintDiscover = 'Search';
  static const String exploreContent = 'Explore content';

  // Navigation / Tabs
  static const String articles = 'Articles';
  static const String blogs = 'Blogs';
  static const String bookmarks = 'Bookmarks';

  // Common Labels
  static const String readFullArticle = 'Read full article';
  static const String readFullBlogPost = 'Read full blog post';
  static const String trending = 'Trending';
  static const String dateUnavailable = 'Date unavailable';
  static const String search = 'Search';
  static const String filter = 'Filter';
  static const String clear = 'Clear';
  static const String retry = 'Retry';
  static const String back = 'Back';
  static const String share = 'Share';
  static const String shareArticle = 'Share article';
  static const String shareBlog = 'Share blog post';
  static const String copyLink = 'Copy link';
  static const String linkCopied = 'Link copied to clipboard';
  static const String noUrlToCopy = 'No link available to copy';
  static const String bookmarkSaved = 'Bookmark saved';
  static const String bookmarkRemoved = 'Bookmark removed';
  static const String openOriginalArticle = 'Open original article';
  static const String openOriginalBlog = 'Open original blog post';
  static const String moreOptions = 'More options';
  static const String refresh = 'Refresh';

  // Loading Messages
  static const String loadingArticles = 'Loading latest articles...';
  static const String loadingBlogs = 'Loading latest blogs...';
  static const String loadingDetails = 'Fetching details...';
  static const String loadingGeneral = 'Please wait...';

  // Empty State Messages
  static const String noArticlesTitle = 'No Articles Found';
  static const String noArticlesSubtitle =
      'There are currently no articles available. Try refreshing or check back later.';
  static const String noBlogsTitle = 'No Blogs Found';
  static const String noBlogsSubtitle =
      'There are currently no blogs available. Try refreshing or check back later.';
  static const String noSearchResultsTitle = 'No Results Found';
  static const String noSearchResultsSubtitle =
      'We could not find anything matching your query. Try a different search term.';

  // Error Messages
  static const String genericError =
      'An unexpected error occurred. Please try again.';
  static const String networkError =
      'No internet connection. Please check your network settings and try again.';
  static const String timeoutError =
      'The connection timed out. Please verify your connection and retry.';
  static const String serverError =
      'Our servers encountered an issue. Please try again later.';
  static const String notFoundError = 'The requested content was not found.';
  static const String unauthorizedError =
      'Authentication failed. Please check your credentials.';
}
