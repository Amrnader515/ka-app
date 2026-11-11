/* Key Account — تطبيق أندرويد: بيفتح الاسكريبت جوه WebView ملء الشاشة */
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

const kUrl =
    'https://script.google.com/macros/s/AKfycbydR5fgOyiC1JxbQqpYQGuulKk9Ph3QF-ThdcCUF3XjYNb-AFeHGNzcPrGKASQLgMOb/exec';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.black,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(const KaApp());
}

class KaApp extends StatelessWidget {
  const KaApp({super.key});
  @override
  Widget build(BuildContext context) => const MaterialApp(
        title: 'Key Account',
        debugShowCheckedModeBanner: false,
        home: Home(),
      );
}

class Home extends StatefulWidget {
  const Home({super.key});
  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late final WebViewController _c;
  bool _loading = true;
  bool _error = false;
  String? _remember;   /* «تذكّرني» محفوظ جوه التطبيق */

  Timer? _watch;

  Uri _startUri() => Uri.parse(_remember == null || _remember!.isEmpty
      ? '$kUrl?app=1'
      : '$kUrl?app=1#kar=${Uri.encodeComponent(_remember!)}');

  /* الاسكريبت بيكتب «تذكّرني» في # بتاع العنوان — التطبيق بيقراه ويحفظه */
  Future<void> _checkUrl(String? url) async {
    if (url == null) return;
    final i = url.indexOf('#');
    if (i < 0) return;
    final m = RegExp(r'(?:^|&)kar=([^&]+)').firstMatch(url.substring(i + 1));
    if (m == null) return;
    final v = Uri.decodeComponent(m.group(1)!);
    final sp = await SharedPreferences.getInstance();
    if (v == '0') {
      if (_remember != null) { _remember = null; await sp.remove('kar'); }
    } else if (v != _remember) {
      _remember = v; await sp.setString('kar', v);
    }
  }

  Future<void> _onStore(String msg) async {
    try {
      final m = jsonDecode(msg) as Map<String, dynamic>;
      final sp = await SharedPreferences.getInstance();
      if (m['t'] == 'save' && m['v'] is String) {
        _remember = m['v'] as String;
        await sp.setString('kar', _remember!);
      } else if (m['t'] == 'clear') {
        _remember = null;
        await sp.remove('kar');
      }
    } catch (_) {}
  }

  bool _inside(Uri u) {
    final h = u.host;
    /* صفحات تسجيل دخول جوجل متفتحش جوه التطبيق — جوجل بيرفضها */
    if (h == 'accounts.google.com' || h.endsWith('.accounts.google.com')) return false;
    return u.scheme == 'about' ||
        u.scheme == 'blob' ||
        u.scheme == 'data' ||
        h.endsWith('google.com') ||
        h.endsWith('googleusercontent.com') ||
        h.endsWith('gstatic.com') ||
        h.endsWith('googleapis.com');
  }

  @override
  void initState() {
    super.initState();
    _c = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel('KAStore', onMessageReceived: (m) => _onStore(m.message))
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (u) {
          if (mounted) setState(() => _loading = false);
          _checkUrl(u);
        },
        onUrlChange: (c) => _checkUrl(c.url),
        onWebResourceError: (e) {
          if (e.isForMainFrame == true && mounted) {
            setState(() {
              _error = true;
              _loading = false;
            });
          }
        },
        onNavigationRequest: (r) {
          final u = Uri.tryParse(r.url);
          if (u == null || _inside(u)) return NavigationDecision.navigate;
          launchUrl(u, mode: LaunchMode.externalApplication);
          return NavigationDecision.prevent;
        },
      ))
      ;
    /* الاسكريبت شغال جوه إطار من دومين جوجل التاني (googleusercontent) —
       من غير السماح ده الأندرويد بيمسح ذاكرته، فـ«تذكّرني» مش بيتحفظ */
    final cm = WebViewCookieManager();
    if (cm.platform is AndroidWebViewCookieManager &&
        _c.platform is AndroidWebViewController) {
      (cm.platform as AndroidWebViewCookieManager).setAcceptThirdPartyCookies(
          _c.platform as AndroidWebViewController, true);
    }
    SharedPreferences.getInstance().then((sp) {
      _remember = sp.getString('kar');
      _c.loadRequest(_startUri());
    });
    _watch = Timer.periodic(const Duration(seconds: 2), (_) async {
      try { _checkUrl(await _c.currentUrl()); } catch (_) {}
    });
  }

  @override
  void dispose() {
    _watch?.cancel();
    super.dispose();
  }

  void _reload() {
    setState(() {
      _error = false;
      _loading = true;
    });
    _c.loadRequest(_startUri());
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _c.canGoBack()) {
          _c.goBack();
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(children: [
            WebViewWidget(controller: _c),
            if (_loading)
              Container(
                color: Colors.black,
                alignment: Alignment.center,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Image.asset('assets/icon.png', width: 110, height: 110),
                  ),
                  const SizedBox(height: 18),
                  const Text('Key Account Application Report',
                      style: TextStyle(color: Color(0xFFC9964A), fontWeight: FontWeight.w700)),
                  const SizedBox(height: 18),
                  const SizedBox(
                      width: 26, height: 26,
                      child: CircularProgressIndicator(strokeWidth: 3, color: Color(0xFFC9964A))),
                ]),
              ),
            if (_error)
              Container(
                color: Colors.black,
                alignment: Alignment.center,
                padding: const EdgeInsets.all(24),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Text('تأكد من الإنترنت وجرب تاني',
                      textDirection: TextDirection.rtl,
                      style: TextStyle(color: Colors.white, fontSize: 16)),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _reload, child: const Text('إعادة المحاولة')),
                ]),
              ),
          ]),
        ),
      ),
    );
  }
}
