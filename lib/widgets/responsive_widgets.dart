import 'package:flutter/material.dart';
import '../utils/responsive_utils.dart';
import '../theme/app_theme.dart';

class ResponsiveScaffold extends StatelessWidget {
  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final Widget? drawer;
  final Color? backgroundColor;
  final bool showBackButton;

  const ResponsiveScaffold({
    Key? key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.drawer,
    this.backgroundColor,
    this.showBackButton = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor ?? AppTheme.background,
      appBar: AppBar(
        title: Text(
          title,
          style: ResponsiveUtils.getHeadingStyle(
            context,
            level: 3,
          ).copyWith(color: Colors.white),
        ),
        backgroundColor: AppTheme.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: showBackButton,
        toolbarHeight: ResponsiveUtils.getAppBarHeight(context),
        actions: actions,
      ),
      drawer: drawer,
      floatingActionButton: floatingActionButton,
      body: ResponsiveUtils.buildResponsiveContainer(
        context: context,
        child: body,
      ),
    );
  }
}

class ResponsiveCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final EdgeInsets? padding;
  final EdgeInsets? margin;
  final Color? color;
  final double? elevation;

  const ResponsiveCard({
    Key? key,
    required this.child,
    this.onTap,
    this.padding,
    this.margin,
    this.color,
    this.elevation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ??
          EdgeInsets.all(ResponsiveUtils.getSpacing(context, size: 'sm')),
      child: Material(
        color: color ?? AppTheme.surface,
        borderRadius: BorderRadius.circular(
          ResponsiveUtils.getSpacing(context, size: 'sm'),
        ),
        elevation: elevation ?? 2,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getSpacing(context, size: 'sm'),
          ),
          child: Padding(
            padding: padding ?? ResponsiveUtils.getResponsivePadding(context),
            child: child,
          ),
        ),
      ),
    );
  }
}

class ResponsiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final Color? color;
  final Color? textColor;
  final IconData? icon;
  final bool isLoading;
  final bool isOutlined;
  final double? width;

  const ResponsiveButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.color,
    this.textColor,
    this.icon,
    this.isLoading = false,
    this.isOutlined = false,
    this.width,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final buttonHeight = ResponsiveUtils.getButtonHeight(context);
    final textStyle = ResponsiveUtils.getBodyStyle(context).copyWith(
      color: textColor ?? (isOutlined ? color : AppTheme.surface),
      fontWeight: FontWeight.w600,
    );

    Widget buttonChild = isLoading
        ? SizedBox(
            height: ResponsiveUtils.getIconSize(context, size: 'sm'),
            width: ResponsiveUtils.getIconSize(context, size: 'sm'),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                textColor ?? AppTheme.surface,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: ResponsiveUtils.getIconSize(context, size: 'sm'),
                  color: textStyle.color,
                ),
                SizedBox(
                  width: ResponsiveUtils.getSpacing(context, size: 'sm'),
                ),
              ],
              Text(text, style: textStyle),
            ],
          );

    return SizedBox(
      height: buttonHeight,
      width: width,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: color ?? Theme.of(context).primaryColor,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getSpacing(context, size: 'xs'),
                  ),
                ),
              ),
              child: buttonChild,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: color ?? Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getSpacing(context, size: 'xs'),
                  ),
                ),
              ),
              child: buttonChild,
            ),
    );
  }
}

class ResponsiveGrid extends StatelessWidget {
  final List<Widget> children;
  final int? maxColumns;
  final double? childAspectRatio;
  final double? crossAxisSpacing;
  final double? mainAxisSpacing;

  const ResponsiveGrid({
    Key? key,
    required this.children,
    this.maxColumns,
    this.childAspectRatio,
    this.crossAxisSpacing,
    this.mainAxisSpacing,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveUtils.buildResponsiveGrid(
      context: context,
      children: children,
      maxColumns: maxColumns,
      childAspectRatio: childAspectRatio,
      crossAxisSpacing: crossAxisSpacing,
      mainAxisSpacing: mainAxisSpacing,
    );
  }
}

class ResponsiveTextField extends StatelessWidget {
  final String? labelText;
  final String? hintText;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final bool obscureText;
  final TextInputType? keyboardType;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;
  final int? maxLines;

  const ResponsiveTextField({
    Key? key,
    this.labelText,
    this.hintText,
    this.controller,
    this.onChanged,
    this.obscureText = false,
    this.keyboardType,
    this.prefixIcon,
    this.suffixIcon,
    this.validator,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      onChanged: onChanged,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      maxLines: maxLines,
      style: ResponsiveUtils.getBodyStyle(context),
      decoration: InputDecoration(
        labelText: labelText,
        hintText: hintText,
        prefixIcon: prefixIcon,
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(
            ResponsiveUtils.getSpacing(context, size: 'xs'),
          ),
        ),
        contentPadding: EdgeInsets.symmetric(
          horizontal: ResponsiveUtils.getSpacing(context, size: 'md'),
          vertical: ResponsiveUtils.getSpacing(context, size: 'sm'),
        ),
      ),
    );
  }
}

class ResponsiveStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ResponsiveStatCard({
    Key? key,
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: ResponsiveUtils.getIconSize(context, size: 'lg'),
              ),
              const Spacer(),
              Text(
                value,
                style: ResponsiveUtils.getHeadingStyle(
                  context,
                  level: 2,
                ).copyWith(color: color),
              ),
            ],
          ),
          SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'sm')),
          Text(title, style: ResponsiveUtils.getCaptionStyle(context)),
        ],
      ),
    );
  }
}

class ResponsiveFeatureCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const ResponsiveFeatureCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      child: ClipRect(
        child: Container(
          padding: EdgeInsets.all(ResponsiveUtils.getSpacing(context, size: 'xs')),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(
                  ResponsiveUtils.getSpacing(context, size: 'xs'),
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(
                    ResponsiveUtils.getSpacing(context, size: 'xs'),
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: ResponsiveUtils.getIconSize(context, size: 'md'),
                ),
              ),
              SizedBox(height: ResponsiveUtils.getSpacing(context, size: 'xs')),
              Text(
                title,
                style: ResponsiveUtils.getCaptionStyle(context).copyWith(
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: ResponsiveUtils.getCaptionStyle(context),
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResponsiveListTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  const ResponsiveListTile({
    Key? key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ResponsiveCard(
      onTap: onTap,
      margin: EdgeInsets.symmetric(
        horizontal: ResponsiveUtils.getSpacing(context, size: 'md'),
        vertical: ResponsiveUtils.getSpacing(context, size: 'xs'),
      ),
      child: Row(
        children: [
          if (leading != null) ...[
            leading!,
            SizedBox(width: ResponsiveUtils.getSpacing(context, size: 'md')),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: ResponsiveUtils.getBodyStyle(context).copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  SizedBox(
                    height: ResponsiveUtils.getSpacing(context, size: 'xs'),
                  ),
                  Text(
                    subtitle!,
                    style: ResponsiveUtils.getCaptionStyle(context),
                  ),
                ],
              ],
            ),
          ),
          if (trailing != null) ...[
            SizedBox(width: ResponsiveUtils.getSpacing(context, size: 'md')),
            trailing!,
          ],
        ],
      ),
    );
  }
}
