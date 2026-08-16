import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:luluna/data/models/skill_level.dart';
import 'package:luluna/features/ai_content/data/mock_ai_services.dart';
import 'package:luluna/features/ai_content/data/openai_ai_services.dart';
import 'package:luluna/features/education/domain/session_ai_question_factory.dart';
import 'package:luluna/features/mathematics/data/math_question_generator.dart';

void main() {
  group('OpenAiAiContentService', () {
    test('parseTeacherPrompt JSON map eder', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'choices': [
                    {
                      'message': {
                        'content': jsonEncode({
                          'activityType': 'math_addition',
                          'difficulty': 'easy',
                          'instruction': 'Topla',
                          'questionText': 'Parkta 2 top + 3 top?',
                          'answer': '5',
                          'choices': ['4', '5', '6', '7'],
                          'characters': [
                            {'name': 'Ali'},
                          ],
                          'objects': [
                            {'type': 'top', 'count': 2, 'location': 'ground'},
                            {'type': 'top', 'count': 3, 'location': 'bag'},
                          ],
                          'operation': 'addition',
                          'explanation': '2+3=5',
                        }),
                      },
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final svc = OpenAiAiContentService(dio: dio, apiKey: 'test-key');
      final a = await svc.parseTeacherPrompt('2+3 top');
      expect(a.answer, '5');
      expect(a.questionText, contains('top'));
      expect(a.choices, contains('5'));
    });

    test('generateSessionQuestions batch üretir', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'choices': [
                    {
                      'message': {
                        'content': jsonEncode({
                          'questions': [
                            {
                              'id': 'q1',
                              'instruction': 'Topla',
                              'questionText': 'Sepette 1 elma, masada 2 elma',
                              'choices': ['2', '3', '4', '5'],
                              'correctAnswer': '3',
                              'explanation': '1+2=3',
                              'type': 'multipleChoice',
                              'sceneCaption': 'Elmalar',
                              'objects': [
                                {'type': 'elma', 'count': 1},
                                {'type': 'elma', 'count': 2},
                              ],
                              'characters': [
                                {'name': 'Ayşe'},
                              ],
                            },
                            {
                              'id': 'q2',
                              'instruction': 'Sırala',
                              'questionText': 'Kim Ne Nerede',
                              'choices': ['Ali', 'Parkta', 'Koşuyor'],
                              'correctAnswer': 'Ali,Koşuyor,Parkta',
                              'correctOrderLabels': [
                                'Ali',
                                'Koşuyor',
                                'Parkta',
                              ],
                              'cardIcons': {
                                'Ali': 'person',
                                'Koşuyor': 'directions_run',
                                'Parkta': 'park',
                              },
                              'type': 'sequence',
                              'sceneCaption': 'Park',
                              'objects': [
                                {'type': 'çocuk', 'count': 1},
                              ],
                              'characters': [
                                {'name': 'Ali'},
                              ],
                            },
                          ],
                        }),
                      },
                    },
                  ],
                },
              ),
            );
          },
        ),
      );

      final svc = OpenAiAiContentService(dio: dio, apiKey: 'test-key');
      final qs = await svc.generateSessionQuestions(
        skill: SkillArea.mathematics,
        category: 'addition',
        difficulty: SkillTier.easy,
        count: 2,
      );
      expect(qs, hasLength(2));
      expect(qs.first.correctAnswer, '3');
      expect(qs[1].metadata['type'], 'sequence');
      expect(qs[1].metadata['visualCards'], isTrue);
    });
  });

  group('OpenAiImageGenerationService', () {
    test('generate URL döner', () async {
      final dio = Dio();
      dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {'url': 'https://example.com/img.png'},
                  ],
                },
              ),
            );
          },
        ),
      );
      final svc = OpenAiImageGenerationService(dio: dio, apiKey: 'test-key');
      final img = await svc.generate(prompt: 'a red ball');
      expect(img.isMock, isFalse);
      expect(img.assetPath, 'https://example.com/img.png');
    });
  });

  group('SessionAiQuestionFactory', () {
    test('anahtar yoksa local generator kullanır', () async {
      final factory = SessionAiQuestionFactory(
        localGenerator: MathQuestionGenerator(random: null),
        batch: OpenAiAiContentService(apiKey: ''),
        images: MockImageGenerationService(),
      );
      expect(factory.canUseAi, isFalse);
      final qs = await factory.build(
        category: 'addition',
        difficulty: SkillTier.easy,
        count: 3,
      );
      expect(qs, hasLength(3));
    });

    test('OpenAI başarılıysa imageUrl http olur', () async {
      final chatDio = Dio();
      chatDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'choices': [
                    {
                      'message': {
                        'content': jsonEncode({
                          'questions': [
                            {
                              'id': 'ai-1',
                              'instruction': 'Topla',
                              'questionText': '2 top + 1 top',
                              'choices': ['2', '3', '4', '5'],
                              'correctAnswer': '3',
                              'explanation': '2+1=3',
                              'type': 'multipleChoice',
                              'sceneCaption': 'Toplar',
                              'objects': [
                                {'type': 'top', 'count': 2},
                                {'type': 'top', 'count': 1},
                              ],
                            },
                          ],
                        }),
                      },
                    },
                  ],
                },
              ),
            );
          },
        ),
      );
      final imgDio = Dio();
      imgDio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            handler.resolve(
              Response(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'data': [
                    {'url': 'https://cdn.example.com/q1.png'},
                  ],
                },
              ),
            );
          },
        ),
      );

      final factory = SessionAiQuestionFactory(
        localGenerator: MathQuestionGenerator(random: null),
        batch: OpenAiAiContentService(dio: chatDio, apiKey: 'sk-test'),
        images: OpenAiImageGenerationService(dio: imgDio, apiKey: 'sk-test'),
      );
      expect(factory.canUseAi, isTrue);
      final qs = await factory.build(
        category: 'addition',
        difficulty: SkillTier.easy,
        count: 1,
      );
      expect(qs, hasLength(1));
      expect(qs.first.imageUrl, 'https://cdn.example.com/q1.png');
      expect(qs.first.metadata['aiGenerated'], isTrue);
    });
  });
}
