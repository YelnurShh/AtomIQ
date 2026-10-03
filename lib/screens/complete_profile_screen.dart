import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../services/app_services.dart';
import '../services/auth_errors.dart';
import '../widgets/ui.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key, required this.onDone});
  final VoidCallback onDone;
  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  final form = GlobalKey<FormState>();
  final name = TextEditingController(text: AppServices.instance.displayName);
  final school = TextEditingController();
  final code = TextEditingController();
  AccountRole role = AccountRole.student;
  bool saving = false;
  String? error;
  @override
  void dispose() {
    name.dispose();
    school.dispose();
    code.dispose();
    super.dispose();
  }

  Future<void> save() async {
    if (!form.currentState!.validate()) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await AppServices.instance.completeProfile(
        name.text,
        school.text,
        role,
        teacherCode: code.text,
      );
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) setState(() => error = authErrorMessage(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> cancel() async {
    setState(() => saving = true);
    try {
      await AppServices.instance.signOut();
      if (mounted) widget.onDone();
    } catch (e) {
      if (mounted) {
        setState(() {
          saving = false;
          error = authErrorMessage(e);
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Профильді аяқтау', style: TextStyle(fontSize: 17)),
      bottom: const AuthorAppBarLine(),
      leading: IconButton(
        onPressed: saving ? null : cancel,
        icon: const Icon(Icons.close),
        tooltip: 'Басқа аккаунтпен кіру',
      ),
    ),
    body: SingleChildScrollView(
      padding: EdgeInsets.all(context.pagePadding),
      child: Form(
        key: form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const BrandMark(size: 52),
            const SizedBox(height: 24),
            Text(
              'Өзіңізбен\nтаныстырыңыз.',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 10),
            Text(AppServices.instance.email),
            const SizedBox(height: 24),
            SegmentedButton<AccountRole>(
              segments: const [
                ButtonSegment(
                  value: AccountRole.student,
                  label: Text('Оқушы'),
                  icon: Icon(Icons.school_outlined),
                ),
                ButtonSegment(
                  value: AccountRole.teacher,
                  label: Text('Мұғалім'),
                  icon: Icon(Icons.co_present_outlined),
                ),
              ],
              selected: {role},
              onSelectionChanged: saving
                  ? null
                  : (v) => setState(() => role = v.single),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: name,
              enabled: !saving,
              decoration: const InputDecoration(labelText: 'Аты-жөніңіз'),
              validator: (v) => (v?.trim().length ?? 0) < 2
                  ? 'Аты-жөніңізді енгізіңіз'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: school,
              enabled: !saving,
              decoration: const InputDecoration(
                labelText: 'Мектеп / оқу орны',
                hintText: 'Міндетті емес',
              ),
            ),
            if (role == AccountRole.teacher) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: code,
                enabled: !saving,
                obscureText: true,
                autocorrect: false,
                decoration: const InputDecoration(
                  labelText: 'Мұғалімнің арнайы коды',
                ),
                validator: (v) => (v?.trim().isEmpty ?? true)
                    ? 'Әкімші берген кодты енгізіңіз'
                    : null,
              ),
              const SizedBox(height: 8),
              const Text(
                'Арнайы кодты жоба әкімшісінен алыңыз.',
                style: TextStyle(fontSize: 11),
              ),
            ],
            if (error != null)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: Text(
                  error!,
                  style: const TextStyle(color: AppColors.coral),
                ),
              ),
            const SizedBox(height: 26),
            PrimaryButton(
              label: 'Профильді сақтау',
              onTap: save,
              loading: saving,
            ),
            const SizedBox(height: 12),
            const Text(
              'Профиль мен нәтижелер аккаунтыңызға байланыстырылып, бұлтта сақталады.',
              style: TextStyle(fontSize: 11),
            ),
          ],
        ),
      ),
    ),
  );
}
