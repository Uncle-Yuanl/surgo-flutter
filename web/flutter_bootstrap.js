{{flutter_js}}
{{flutter_build_config}}

// 兜底字体从站点自己的 fonts/ 取（tool/vercel_build.sh 构建时拷进去），不找 fonts.gstatic.com。
_flutter.loader.load({
  config: { fontFallbackBaseUrl: "fonts/" },
});
