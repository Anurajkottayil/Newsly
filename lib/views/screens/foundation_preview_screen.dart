import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_dimensions.dart';
import '../../core/constants/app_strings.dart';
import '../../models/article_model.dart';
import '../../shared/widgets/app_button.dart';
import '../../shared/widgets/app_empty_view.dart';
import '../../shared/widgets/app_error_view.dart';
import '../../shared/widgets/app_loader.dart';
import '../../shared/widgets/article_card.dart';
import '../../viewmodels/article_view_model.dart';
import '../../viewmodels/blog_view_model.dart';
import '../widgets/responsive_layout.dart';

/// Foundation preview and validation screen showcasing the configured architecture,
/// state management, theme system, and shared components.
class FoundationPreviewScreen extends StatefulWidget {
  final ValueNotifier<ThemeMode> themeModeNotifier;

  const FoundationPreviewScreen({super.key, required this.themeModeNotifier});

  @override
  State<FoundationPreviewScreen> createState() =>
      _FoundationPreviewScreenState();
}

class _FoundationPreviewScreenState extends State<FoundationPreviewScreen> {
  int _selectedTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.space6),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: const Icon(
                Icons.newspaper_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
            const Text(AppStrings.appName),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Toggle Theme',
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            ),
            onPressed: () {
              widget.themeModeNotifier.value = isDark
                  ? ThemeMode.light
                  : ThemeMode.dark;
            },
          ),
          const SizedBox(width: AppDimensions.space8),
        ],
      ),
      body: ResponsiveLayout(mobile: _buildContent(context)),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedTabIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedTabIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.architecture_rounded),
            label: 'Architecture',
          ),
          NavigationDestination(
            icon: Icon(Icons.widgets_outlined),
            selectedIcon: Icon(Icons.widgets_rounded),
            label: 'Shared UI',
          ),
          NavigationDestination(
            icon: Icon(Icons.palette_outlined),
            selectedIcon: Icon(Icons.palette_rounded),
            label: 'Theme',
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    switch (_selectedTabIndex) {
      case 0:
        return _buildArchitectureStatusTab(context);
      case 1:
        return _buildSharedWidgetsTab(context);
      case 2:
        return _buildThemePaletteTab(context);
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildArchitectureStatusTab(BuildContext context) {
    final articleVm = context.watch<ArticleViewModel>();
    final blogVm = context.watch<BlogViewModel>();
    final theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      children: [
        _buildSectionHeader(
          context,
          title: 'Newsly Architecture Foundation',
          subtitle:
              'MVVM with Provider, Dio network client, and cached images configured.',
        ),
        const SizedBox(height: AppDimensions.space16),
        _buildInfoCard(
          context,
          icon: Icons.hub_rounded,
          title: 'State Management: Provider + ChangeNotifier',
          subtitle:
              'ArticleViewModel (${articleVm.state.name}) & BlogViewModel (${blogVm.state.name}) registered in MultiProvider tree.',
          statusText: 'Active',
          statusColor: AppColors.success,
        ),
        const SizedBox(height: AppDimensions.space12),
        _buildInfoCard(
          context,
          icon: Icons.cloud_done_rounded,
          title: 'Networking: Dio HTTP Client',
          subtitle:
              'Spaceflight News API (v4) with connection & receive timeouts (15s) and typed ApiExceptions.',
          statusText: 'Configured',
          statusColor: AppColors.success,
        ),
        const SizedBox(height: AppDimensions.space12),
        _buildInfoCard(
          context,
          icon: Icons.layers_rounded,
          title: 'Repository Layer',
          subtitle:
              'ArticleRepository & BlogRepository decouple network operations from ViewModels.',
          statusText: 'Ready',
          statusColor: AppColors.success,
        ),
        const SizedBox(height: AppDimensions.space12),
        _buildInfoCard(
          context,
          icon: Icons.devices_rounded,
          title: 'Responsive Design Foundation',
          subtitle:
              'Adaptive breakpoints for phones, tablets (<600dp / >=600dp), and iPads.',
          statusText: 'Enabled',
          statusColor: AppColors.success,
        ),
        const SizedBox(height: AppDimensions.space24),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick Network Verification',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Text(
                  'Trigger a sample API call to verify the network and repository layers:',
                  style: theme.textTheme.bodySmall,
                ),
                const SizedBox(height: AppDimensions.space16),
                Row(
                  children: [
                    Expanded(
                      child: AppButton(
                        label: 'Fetch Articles',
                        isLoading: articleVm.isLoading,
                        onPressed: () => articleVm.fetchArticles(),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space12),
                    Expanded(
                      child: AppButton.outlined(
                        label: 'Fetch Blogs',
                        isLoading: blogVm.isLoading,
                        onPressed: () => blogVm.fetchBlogs(),
                      ),
                    ),
                  ],
                ),
                if (articleVm.errorMessage != null) ...[
                  const SizedBox(height: AppDimensions.space12),
                  Text(
                    'Article Error: ${articleVm.errorMessage}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (articleVm.articles.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.space12),
                  Text(
                    'Success: Loaded ${articleVm.articles.length} of ${articleVm.totalCount} articles from API.',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
                if (blogVm.blogs.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.space6),
                  Text(
                    'Success: Loaded ${blogVm.blogs.length} of ${blogVm.totalCount} blogs from API.',
                    style: const TextStyle(
                      color: AppColors.success,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSharedWidgetsTab(BuildContext context) {
    final sampleArticle = Article(
      id: 1,
      title: 'NASA and SpaceX Prepare for Next High-Altitude Mission',
      authors: const [Author(name: 'Editorial Team')],
      url: 'https://example.com',
      imageUrl: 'https://images.unsplash.com/photo-1517976487502-5f79e948a04c',
      newsSite: 'NASA Spaceflight',
      summary:
          'Teams at Cape Canaveral are conducting flight readiness reviews ahead of the upcoming launch window.',
      publishedAt: DateTime.now().subtract(const Duration(hours: 3)),
      featured: true,
    );

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      children: [
        _buildSectionHeader(
          context,
          title: 'Shared Reusable Components',
          subtitle:
              'DRY-compliant widgets designed for reuse across both Articles and Blogs views.',
        ),
        const SizedBox(height: AppDimensions.space16),
        const Text(
          'ArticleCard Component',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: AppDimensions.space8),
        ArticleCard.fromArticle(article: sampleArticle, onTap: () {}),
        const SizedBox(height: AppDimensions.space24),
        const Text(
          'Buttons (AppButton)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: AppDimensions.space8),
        Row(
          children: [
            Expanded(
              child: AppButton(label: 'Primary', onPressed: () {}),
            ),
            const SizedBox(width: AppDimensions.space8),
            Expanded(
              child: AppButton(
                label: 'Secondary',
                variant: AppButtonVariant.secondary,
                onPressed: () {},
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            Expanded(
              child: AppButton.outlined(label: 'Outlined', onPressed: () {}),
            ),
          ],
        ),
        const SizedBox(height: AppDimensions.space24),
        const Text(
          'Loading View (AppLoader)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: AppDimensions.space8),
        const Card(
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: AppDimensions.space16),
            child: AppLoader(message: 'Testing AppLoader with custom message'),
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        const Text(
          'Empty View (AppEmptyView)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: AppDimensions.space8),
        Card(
          child: AppEmptyView(
            title: AppStrings.noArticlesTitle,
            message: AppStrings.noArticlesSubtitle,
            actionLabel: 'Refresh',
            onAction: () {},
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        const Text(
          'Error View (AppErrorView)',
          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: AppDimensions.space8),
        Card(
          child: AppErrorView(
            title: 'Sample Error',
            message: AppStrings.networkError,
            onRetry: () {},
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
      ],
    );
  }

  Widget _buildThemePaletteTab(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      children: [
        _buildSectionHeader(
          context,
          title: 'Color Palette & Typography',
          subtitle:
              'Centralized tokens from AppColors & AppTheme conforming to Material 3.',
        ),
        const SizedBox(height: AppDimensions.space16),
        _buildColorTile('Primary', colorScheme.primary, colorScheme.onPrimary),
        _buildColorTile(
          'Secondary',
          colorScheme.secondary,
          colorScheme.onSecondary,
        ),
        _buildColorTile('Surface', colorScheme.surface, colorScheme.onSurface),
        _buildColorTile(
          'Background',
          theme.scaffoldBackgroundColor,
          colorScheme.onSurface,
        ),
        _buildColorTile('Error', colorScheme.error, colorScheme.onError),
        const SizedBox(height: AppDimensions.space24),
        Text(
          'Typography Scale',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppDimensions.space12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Display / Title: Newsly Headline',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Title Medium: Space Exploration Article',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Body Large: Full-length body text with comfortable reading line height.',
                  style: theme.textTheme.bodyLarge,
                ),
                const SizedBox(height: 8),
                Text(
                  'Body Medium: Secondary summary description and details.',
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Body Small / Meta: Published on Nov 17, 2026 • 5 min read',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildColorTile(String name, Color bg, Color fg) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppDimensions.space8),
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            name,
            style: TextStyle(color: fg, fontWeight: FontWeight.w600),
          ),
          Text(
            '#${bg.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}',
            style: TextStyle(
              color: fg.withValues(alpha: 0.8),
              fontFamily: 'monospace',
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        const SizedBox(height: AppDimensions.space4),
        Text(
          subtitle,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required String statusText,
    required Color statusColor,
  }) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.space12),
              decoration: BoxDecoration(
                color: theme.colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(AppDimensions.radiusSm),
              ),
              child: Icon(icon, color: theme.colorScheme.primary, size: 24),
            ),
            const SizedBox(width: AppDimensions.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space8,
                          vertical: AppDimensions.space2,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(
                            AppDimensions.radiusXs,
                          ),
                        ),
                        child: Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(
                        alpha: 0.65,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
