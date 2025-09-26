import 'package:flutter/material.dart';
import '../utils/app_theme.dart';

class ProfileStatsCard extends StatefulWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color? color;
  final VoidCallback? onTap;
  final bool isFarmer;

  const ProfileStatsCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.onTap,
    this.isFarmer = false,
  });

  @override
  State<ProfileStatsCard> createState() => _ProfileStatsCardState();
}

class _ProfileStatsCardState extends State<ProfileStatsCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => _animationController.reverse(),
      onTapUp: (_) => _animationController.forward(),
      onTapCancel: () => _animationController.forward(),
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isFarmer
                        ? [
                            AppTheme.primaryGreen.withOpacity(0.1),
                            AppTheme.accentGreen.withOpacity(0.05),
                          ]
                        : [
                            AppTheme.primaryGreen.withOpacity(0.1),
                            AppTheme.accentGreen.withOpacity(0.05),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: (widget.color ?? AppTheme.primaryGreen).withOpacity(0.2),
                    width: 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (widget.color ?? AppTheme.primaryGreen).withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                    BoxShadow(
                      color: Colors.white.withOpacity(0.8),
                      blurRadius: 10,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            (widget.color ?? AppTheme.primaryGreen).withOpacity(0.2),
                            (widget.color ?? AppTheme.primaryGreen).withOpacity(0.1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: (widget.color ?? AppTheme.primaryGreen).withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Icon(
                        widget.icon,
                        color: widget.color ?? AppTheme.primaryGreen,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      widget.value,
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.title,
                      style: AppTheme.caption.copyWith(
                        color: AppTheme.darkGray,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class ProfileInfoCard extends StatelessWidget {
  final String title;
  final String? subtitle;
  final IconData icon;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color? iconColor;

  const ProfileInfoCard({
    super.key,
    required this.title,
    this.subtitle,
    required this.icon,
    this.trailing,
    this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (iconColor ?? AppTheme.primaryGreen).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: iconColor ?? AppTheme.primaryGreen,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: AppTheme.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle!,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkGray,
                ),
              )
            : null,
        trailing: onTap != null 
            ? (trailing ??
                Icon(
                  Icons.arrow_forward_ios,
                  size: 16,
                  color: AppTheme.darkGray,
                ))
            : null,
      ),
    );
  }
}

class ProfileSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? action;

  const ProfileSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTheme.heading3.copyWith(
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    subtitle!,
                    style: AppTheme.bodyMedium.copyWith(
                      color: AppTheme.darkGray,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (action != null) action!,
        ],
      ),
    );
  }
}

class ProfileChip extends StatelessWidget {
  final String label;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;

  const ProfileChip({
    super.key,
    required this.label,
    this.backgroundColor,
    this.textColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppTheme.lightGreen,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: (backgroundColor ?? AppTheme.lightGreen).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(
              icon,
              size: 14,
              color: textColor ?? AppTheme.primaryGreen,
            ),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: AppTheme.caption.copyWith(
              color: textColor ?? AppTheme.primaryGreen,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileRatingWidget extends StatelessWidget {
  final double rating;
  final int totalReviews;
  final bool showReviews;

  const ProfileRatingWidget({
    super.key,
    required this.rating,
    required this.totalReviews,
    this.showReviews = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Row(
          children: List.generate(5, (index) {
            return Icon(
              index < rating.floor()
                  ? Icons.star
                  : index < rating
                      ? Icons.star_half
                      : Icons.star_border,
              color: AppTheme.accentGreen,
              size: 16,
            );
          }),
        ),
        const SizedBox(width: 8),
        Text(
          rating.toStringAsFixed(1),
          style: AppTheme.bodyMedium.copyWith(
            fontWeight: FontWeight.w600,
            color: AppTheme.textDark,
          ),
        ),
        if (showReviews) ...[
          const SizedBox(width: 4),
          Text(
            '($totalReviews reviews)',
            style: AppTheme.caption.copyWith(
              color: AppTheme.darkGray,
            ),
          ),
        ],
      ],
    );
  }
}

class ProfileBioCard extends StatefulWidget {
  final String bio;
  final VoidCallback? onEdit;

  const ProfileBioCard({
    super.key,
    required this.bio,
    this.onEdit,
  });

  @override
  State<ProfileBioCard> createState() => _ProfileBioCardState();
}

class _ProfileBioCardState extends State<ProfileBioCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white,
                AppTheme.lightGreen.withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppTheme.primaryGreen.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
              BoxShadow(
                color: Colors.white.withOpacity(0.8),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.2),
                          AppTheme.accentGreen.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.info_outline,
                      color: AppTheme.primaryGreen,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'About',
                    style: AppTheme.heading3.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textDark,
                    ),
                  ),
                  const Spacer(),
                  if (widget.onEdit != null)
                    GestureDetector(
                      onTap: widget.onEdit,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.edit,
                          color: AppTheme.primaryGreen,
                          size: 18,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                widget.bio,
                style: AppTheme.bodyMedium.copyWith(
                  color: AppTheme.darkGray,
                  height: 1.6,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// New Modern Crop Tag Widget
class ModernCropTag extends StatefulWidget {
  final String crop;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isFarmer;

  const ModernCropTag({
    super.key,
    required this.crop,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.isFarmer = false,
  });

  @override
  State<ModernCropTag> createState() => _ModernCropTagState();
}

class _ModernCropTagState extends State<ModernCropTag>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: widget.isFarmer
                  ? AppTheme.primaryGreen.withOpacity(0.15)
                  : (widget.backgroundColor ?? AppTheme.primaryGreen.withOpacity(0.1)),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(
                color: (widget.backgroundColor ?? AppTheme.primaryGreen).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: (widget.backgroundColor ?? AppTheme.primaryGreen).withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (widget.icon != null) ...[
                  Icon(
                    widget.icon,
                    size: 16,
                    color: widget.textColor ?? AppTheme.primaryGreen,
                  ),
                  const SizedBox(width: 6),
                ],
                Text(
                  widget.crop,
                  style: AppTheme.caption.copyWith(
                    color: widget.textColor ?? AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Enhanced Profile Section Header
class ModernProfileSectionHeader extends StatefulWidget {
  final String title;
  final String? subtitle;
  final Widget? action;
  final bool isFarmer;

  const ModernProfileSectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
    this.isFarmer = false,
  });

  @override
  State<ModernProfileSectionHeader> createState() => _ModernProfileSectionHeaderState();
}

class _ModernProfileSectionHeaderState extends State<ModernProfileSectionHeader>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    
    _slideAnimation = Tween<Offset>(
      begin: const Offset(-0.3, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: widget.isFarmer
                        ? [
                            AppTheme.primaryGreen.withOpacity(0.2),
                            AppTheme.accentGreen.withOpacity(0.1),
                          ]
                        : [
                            AppTheme.primaryGreen.withOpacity(0.2),
                            AppTheme.accentGreen.withOpacity(0.1),
                          ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  widget.isFarmer ? Icons.agriculture : Icons.shopping_bag,
                  color: AppTheme.primaryGreen,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: AppTheme.heading3.copyWith(
                        color: AppTheme.textDark,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    if (widget.subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        widget.subtitle!,
                        style: AppTheme.bodyMedium.copyWith(
                          color: AppTheme.darkGray,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (widget.action != null) widget.action!,
            ],
          ),
        ),
      ),
    );
  }
}
