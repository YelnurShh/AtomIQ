import 'package:flutter/material.dart';
import '../core/app_theme.dart';
import '../widgets/ui.dart';

class GuideScreen extends StatelessWidget {
  const GuideScreen({super.key});
  static const steps = [
    (
      'Формулаларды тексеріңіз',
      'Реагенттер мен өнімдердің формулалары дұрыс па? AI заттың формуласын өзгертіп жібермегеніне көз жеткізіңіз.',
    ),
    (
      'Атомдарды санаңыз',
      'Әр элементтің атом санын теңдеудің екі жағында бөлек есептеңіз. Жақша мен индексті ескеріңіз.',
    ),
    (
      'Коэффициенттерді салыстырыңыз',
      'Индекстер өзгермейді. Коэффициенттер оң бүтін сандар болуы және ортақ бөлгіші 1 болуы керек.',
    ),
    (
      'Балансты растаңыз',
      'Әр элемент атомдарының саны екі жақта тең болуы керек. Иондық теңдеуде жалпы зарядты да тексеріңіз.',
    ),
    (
      'Түсіндірмені бағалаңыз',
      'AI жауабындағы әр қадамды қайта есептеңіз. Атомдардың теңдігі реакцияның шын мәнінде жүретінін дәлелдемейді.',
    ),
  ];
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      bottom: const AuthorAppBarLine(),
      title: const Text(
        'Тексеру әдістемесі',
        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
      ),
    ),
    body: ListView(
      padding: EdgeInsets.all(context.pagePadding),
      children: [
        const TagLabel('Сенімді жауапқа 5 қадам'),
        const SizedBox(height: 16),
        Text(
          'AI жауабын\nбірге тексерейік.',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        const SizedBox(height: 12),
        const Text(
          'Оқушыға — өзін тексеру, мұғалімге — түсінуді бағалау құралы.',
        ),
        const SizedBox(height: 24),
        ...steps.indexed.map(
          (entry) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: SoftCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: AppColors.soft,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '0${entry.$1 + 1}',
                          style: formulaStyle(
                            color: AppColors.blue,
                            weight: FontWeight.w700,
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.$2.$1,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(entry.$2.$2),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        const AuthorPill(),
      ],
    ),
  );
}
