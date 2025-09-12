import 'package:flutter/material.dart';

List<Map<String, dynamic>> allQuestions() {
  List<Map<String, dynamic>> malariaQuiz = [
    {
      "question": "Como a malária é transmitida ?",
      "options": [
        "Pelo ar",
        "Pessoa através do contato físico",
        "Pelo consumo de água contaminada",
        "Por mosquitos infectados",
        "Hereditário"
      ],
      "correctAnswer": "Por mosquitos infectados"
    },
    {
      "question": "O que causa a malária?",
      "options": ["Vírus", "Bactéria", "Parasita", "Fungo"],
      "correctAnswer": "Parasita"
    },
    {
      "question":
          "Qual gênero de mosquito é o principal transmissor da malária?",
      "options": ["Aedes", "Culex", "Anopheles", "Mansonia"],
      "correctAnswer": "Anopheles"
    },
    {
      "question":
          "Qual parasita é mais comumente associado à forma grave de malária?",
      "options": [
        "Plasmodium vivax",
        "Plasmodium falciparum",
        "Plasmodium ovale",
        "Plasmodium malariae"
      ],
      "correctAnswer": "Plasmodium falciparum"
    },
    {
      "question": "Qual é o principal sintoma inicial da malária?",
      "options": [
        "Tosse seca",
        "Febre",
        "Dor nas articulações",
        "Erupção cutânea"
      ],
      "correctAnswer": "Febre"
    },
    {
      "question":
          "Em que parte do corpo humano o parasita da malária se multiplica inicialmente?",
      "options": ["Pulmões", "Fígado", "Rins", "Coração"],
      "correctAnswer": "Fígado"
    },
    {
      "question": "Qual é uma medida eficaz para prevenir a malária?",
      "options": [
        "Beber água fervida",
        "Usar repelente de insetos",
        "Tomar antibióticos",
        "Evitar frutas tropicais"
      ],
      "correctAnswer": "Usar repelente de insetos"
    },
    {
      "question":
          "Qual medicamento é frequentemente usado no tratamento da malária?",
      "options": ["Penicilina", "Cloroquina", "Ibuprofeno", "Paracetamol"],
      "correctAnswer": "Cloroquina"
    },
    {
      "question": "Em que continente a malária é mais prevalente?",
      "options": ["Ásia", "Europa", "África", "Oceania"],
      "correctAnswer": "África"
    },
    {
      "question":
          "Qual é o nome do ciclo de vida do parasita da malária no mosquito?",
      "options": ["Esporogonia", "Gametogonia", "Merozoítos", "Trofozoítos"],
      "correctAnswer": "Esporogonia"
    },
    {
      "question":
          "Qual complicação grave pode ocorrer em casos de malária não tratada?",
      "options": [
        "Cegueira",
        "Malária cerebral",
        "Perda de audição",
        "Fratura óssea"
      ],
      "correctAnswer": "Malária cerebral"
    },
    {
      "question": "Qual é o vetor da malária?",
      "options": ["Mosca doméstica", "Mosquito Anopheles", "Barata", "Pulga"],
      "correctAnswer": "Mosquito Anopheles"
    },
    {
      "question":
          "Qual espécie de Plasmodium pode permanecer dormente no fígado?",
      "options": [
        "Plasmodium falciparum",
        "Plasmodium vivax",
        "Plasmodium malariae",
        "Plasmodium knowlesi"
      ],
      "correctAnswer": "Plasmodium vivax"
    },
    {
      "question": "Qual é o período típico de incubação da malária?",
      "options": ["1-2 dias", "7-30 dias", "2-3 meses", "6-12 meses"],
      "correctAnswer": "7-30 dias"
    },
    {
      "question": "Qual exame é mais usado para diagnosticar a malária?",
      "options": ["Raio-X", "Gota espessa", "Tomografia", "Ultrassom"],
      "correctAnswer": "Gota espessa"
    },
    {
      "question": "O que o mosquito Anopheles injeta ao picar uma pessoa?",
      "options": ["Vírus", "Esporozoítos", "Bactérias", "Toxinas"],
      "correctAnswer": "Esporozoítos"
    },
    {
      "question": "Qual é um sintoma comum da malária além da febre?",
      "options": [
        "Dor de cabeça",
        "Coceira na pele",
        "Visão dupla",
        "Perda de olfato"
      ],
      "correctAnswer": "Dor de cabeça"
    },
    {
      "question": "Qual é a principal fonte de infecção da malária?",
      "options": [
        "Água contaminada",
        "Picada de mosquito",
        "Alimentos crus",
        "Contato com sangue"
      ],
      "correctAnswer": "Picada de mosquito"
    },
    {
      "question":
          "Qual estação do ano favorece a proliferação do mosquito Anopheles?",
      "options": [
        "Inverno seco",
        "Verão chuvoso",
        "Outono frio",
        "Primavera seca"
      ],
      "correctAnswer": "Verão chuvoso"
    },
    {
      "question":
          "Qual é o nome da célula infectada pelo parasita na corrente sanguínea?",
      "options": ["Leucócito", "Hemácia", "Plaqueta", "Neurônio"],
      "correctAnswer": "Hemácia"
    },
    {
      "question": "Qual é uma consequência da malária grave em crianças?",
      "options": [
        "Anemia severa",
        "Crescimento acelerado",
        "Melhora da visão",
        "Aumento de peso"
      ],
      "correctAnswer": "Anemia severa"
    },
    {
      "question": "Qual é o objetivo da rede mosquiteira no combate à malária?",
      "options": [
        "Filtrar água",
        "Proteger contra picadas",
        "Aquecer o ambiente",
        "Capturar mosquitos"
      ],
      "correctAnswer": "Proteger contra picadas"
    },
  ];
  return malariaQuiz;
}

List<Map<String, dynamic>> englishQuestions() {
  List<Map<String, dynamic>> malariaQuiz = [
    {
      "question": "How is malaria transmitted?",
      "options": [
        "By air",
        "Person-to-person through physical contact",
        "By consuming contaminated water",
        "By infected mosquitoes",
        "Hereditary"
      ],
      "correctAnswer": "By infected mosquitoes"
    },
    {
      "question": "What causes malaria?",
      "options": ["Virus", "Bacterium", "Parasite", "Fungus"],
      "correctAnswer": "Parasite"
    },
    {
      "question": "What genus of mosquito is the main transmitter of malaria?",
      "options": ["Aedes", "Culex", "Anopheles", "Mansonia"],
      "correctAnswer": "Anopheles"
    },
    {
      "question":
          "Which parasite is most commonly associated with the severe form of malaria?",
      "options": [
        "Plasmodium vivax",
        "Plasmodium falciparum",
        "Plasmodium ovale",
        "Plasmodium malariae"
      ],
      "correctAnswer": "Plasmodium falciparum"
    },
    {
      "question": "What is the main initial symptom of malaria?",
      "options": ["Dry cough", "Fever", "Joint pain", "Skin rash"],
      "correctAnswer": "Fever"
    },
    {
      "question":
          "In which part of the human body does the malaria parasite initially multiply?",
      "options": ["Lungs", "Liver", "Kidneys", "Heart"],
      "correctAnswer": "Liver"
    },
    {
      "question": "What is an effective measure to prevent malaria?",
      "options": [
        "Drinking boiled water",
        "Using insect repellent",
        "Taking antibiotics",
        "Avoiding tropical fruits"
      ],
      "correctAnswer": "Using insect repellent"
    },
    {
      "question": "What medicine is often used in the treatment of malaria?",
      "options": ["Penicillin", "Chloroquine", "Ibuprofen", "Paracetamol"],
      "correctAnswer": "Chloroquine"
    },
    {
      "question": "In which continent is malaria most prevalent?",
      "options": ["Asia", "Europe", "Africa", "Oceania"],
      "correctAnswer": "Africa"
    },
    {
      "question":
          "What is the name of the malaria parasite's life cycle in the mosquito?",
      "options": ["Sporogony", "Gametogony", "Merozoites", "Trophozoites"],
      "correctAnswer": "Sporogony"
    },
    {
      "question":
          "What serious complication can occur in cases of untreated malaria?",
      "options": [
        "Blindness",
        "Cerebral malaria",
        "Hearing loss",
        "Bone fracture"
      ],
      "correctAnswer": "Cerebral malaria"
    },
    {
      "question": "What is the vector of malaria?",
      "options": ["Housefly", "Anopheles mosquito", "Cockroach", "Flea"],
      "correctAnswer": "Anopheles mosquito"
    },
    {
      "question":
          "Which species of Plasmodium can remain dormant in the liver?",
      "options": [
        "Plasmodium falciparum",
        "Plasmodium vivax",
        "Plasmodium malariae",
        "Plasmodium knowlesi"
      ],
      "correctAnswer": "Plasmodium vivax"
    },
    {
      "question": "What is the typical incubation period for malaria?",
      "options": ["1-2 days", "7-30 days", "2-3 months", "6-12 months"],
      "correctAnswer": "7-30 days"
    },
    {
      "question": "What test is most commonly used to diagnose malaria?",
      "options": ["X-ray", "Thick smear", "CT scan", "Ultrasound"],
      "correctAnswer": "Thick smear"
    },
    {
      "question":
          "What does the Anopheles mosquito inject when it bites a person?",
      "options": ["Virus", "Sporozoites", "Bacteria", "Toxins"],
      "correctAnswer": "Sporozoites"
    },
    {
      "question": "What is a common symptom of malaria besides fever?",
      "options": ["Headache", "Skin itching", "Double vision", "Loss of smell"],
      "correctAnswer": "Headache"
    },
    {
      "question": "What is the main source of malaria infection?",
      "options": [
        "Contaminated water",
        "Mosquito bite",
        "Raw food",
        "Blood contact"
      ],
      "correctAnswer": "Mosquito bite"
    },
    {
      "question":
          "Which season favors the proliferation of the Anopheles mosquito?",
      "options": ["Dry winter", "Rainy summer", "Cold autumn", "Dry spring"],
      "correctAnswer": "Rainy summer"
    },
    {
      "question":
          "What is the name of the cell infected by the parasite in the bloodstream?",
      "options": ["Leukocyte", "Red blood cell", "Platelet", "Neuron"],
      "correctAnswer": "Red blood cell"
    },
    {
      "question": "What is a consequence of severe malaria in children?",
      "options": [
        "Severe anemia",
        "Accelerated growth",
        "Improved vision",
        "Weight gain"
      ],
      "correctAnswer": "Severe anemia"
    },
    {
      "question":
          "What is the purpose of a mosquito net in the fight against malaria?",
      "options": [
        "Filtering water",
        "Protecting against bites",
        "Heating the environment",
        "Capturing mosquitoes"
      ],
      "correctAnswer": "Protecting against bites"
    },
  ];
  return malariaQuiz;
}

List<Map<String, dynamic>> japaneseQuestions() {
  List<Map<String, dynamic>> malariaQuiz = [
    {
      "question": "マラリアはどのようにして感染しますか？",
      "options": [
        "空気によって",
        "身体的接触による人から人への接触",
        "汚染された水の消費によって",
        "感染した蚊によって",
        "遺伝性"
      ],
      "correctAnswer": "感染した蚊によって"
    },
    {
      "question": "マラリアの原因は何ですか？",
      "options": ["ウイルス", "バクテリア", "寄生虫", "真菌"],
      "correctAnswer": "寄生虫"
    },
    {
      "question": "マラリアを主に媒介する蚊の属は何ですか？",
      "options": ["ネッタイシマカ", "イエカ", "アノフェレス", "マンソニア"],
      "correctAnswer": "アノフェレス"
    },
    {
      "question": "重症マラリアと最も関連が深い寄生虫は何ですか？",
      "options": ["マラリア原虫", "熱帯熱マラリア原虫", "卵形マラリア原虫", "三日熱マラリア原虫"],
      "correctAnswer": "熱帯熱マラリア原虫"
    },
    {
      "question": "マラリアの主な初期症状は何ですか？",
      "options": ["乾いた咳", "発熱", "関節痛", "皮膚の発疹"],
      "correctAnswer": "発熱"
    },
    {
      "question": "マラリア原虫が最初に体内で増殖する場所はどこですか？",
      "options": ["肺", "肝臓", "腎臓", "心臓"],
      "correctAnswer": "肝臓"
    },
    {
      "question": "マラリアを予防する効果的な手段は何ですか？",
      "options": ["煮沸した水を飲むこと", "虫除けを使用すること", "抗生物質を服用すること", "熱帯の果物を避けること"],
      "correctAnswer": "虫除けを使用すること"
    },
    {
      "question": "マラリアの治療に頻繁に使用される薬は何ですか？",
      "options": ["ペニシリン", "クロロキン", "イブプロフェン", "パラセタモール"],
      "correctAnswer": "クロロキン"
    },
    {
      "question": "マラリアが最も蔓延している大陸はどこですか？",
      "options": ["アジア", "ヨーロッパ", "アフリカ", "オセアニア"],
      "correctAnswer": "アフリカ"
    },
    {
      "question": "マラリア原虫の蚊の中での生活環は何と呼ばれますか？",
      "options": ["スポロゴニー", "ガメトゴニー", "メロゾイト", "トロフォゾイト"],
      "correctAnswer": "スポロゴニー"
    },
    {
      "question": "マラリアを治療しない場合に起こる可能性のある深刻な合併症は何ですか？",
      "options": ["失明", "脳マラリア", "聴力損失", "骨折"],
      "correctAnswer": "脳マラリア"
    },
    {
      "question": "マラリアの媒介生物は何ですか？",
      "options": ["イエバエ", "アノフェレス蚊", "ゴキブリ", "ノミ"],
      "correctAnswer": "アノフェレス蚊"
    },
    {
      "question": "肝臓に潜伏できるプラスモジウム種は何ですか？",
      "options": ["熱帯熱マラリア原虫", "マラリア原虫", "三日熱マラリア原虫", "熱帯熱マラリア原虫"],
      "correctAnswer": "マラリア原虫"
    },
    {
      "question": "マラリアの一般的な潜伏期間はどれくらいですか？",
      "options": ["1-2日", "7-30日", "2-3ヶ月", "6-12ヶ月"],
      "correctAnswer": "7-30日"
    },
    {
      "question": "マラリアの診断に最もよく使われる検査は何ですか？",
      "options": ["X線", "厚層塗抹標本", "CTスキャン", "超音波"],
      "correctAnswer": "厚層塗抹標本"
    },
    {
      "question": "アノフェレス蚊が人を刺したときに何を注入しますか？",
      "options": ["ウイルス", "スポロゾイト", "バクテリア", "毒素"],
      "correctAnswer": "スポロゾイト"
    },
    {
      "question": "発熱に加えて、マラリアの一般的な症状は何ですか？",
      "options": ["頭痛", "皮膚のかゆみ", "複視", "嗅覚の喪失"],
      "correctAnswer": "頭痛"
    },
    {
      "question": "マラリアの主な感染源は何ですか？",
      "options": ["汚染された水", "蚊に刺されること", "生の食物", "血液との接触"],
      "correctAnswer": "蚊に刺されること"
    },
    {
      "question": "アノフェレス蚊の増殖に有利な季節はいつですか？",
      "options": ["乾燥した冬", "雨季の夏", "寒い秋", "乾燥した春"],
      "correctAnswer": "雨季の夏"
    },
    {
      "question": "マラリア原虫が血流で感染する細胞の名前は何ですか？",
      "options": ["白血球", "赤血球", "血小板", "ニューロン"],
      "correctAnswer": "赤血球"
    },
    {
      "question": "小児の重症マラリアの合併症は何ですか？",
      "options": ["重度の貧血", "成長加速", "視力向上", "体重増加"],
      "correctAnswer": "重度の貧血"
    },
    {
      "question": "マラリア対策における蚊帳の目的は何ですか？",
      "options": ["水をろ過すること", "刺されることから身を守ること", "周囲を暖めること", "蚊を捕獲すること"],
      "correctAnswer": "刺されることから身を守ること"
    },
  ];
  return malariaQuiz;
}
