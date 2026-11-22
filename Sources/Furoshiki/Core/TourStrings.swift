// SPDX-License-Identifier: GPL-3.0-or-later
// Copyright (C) 2026 Vorssaint
// Modified for Furoshiki: feature manager in the panel and the setup tour.

import Foundation

/// Strings for the panel's feature manager and the short tour at the end of
/// setup. Same contract as the other FeatureStrings structs: memberwise init
/// with labeled arguments in declaration order, one static per language, all
/// in this file. The tour names the panel buttons by their real labels
/// (`FeatureHubStrings.pageTitle`, `Strings.panelSettings`).
struct TourStrings {
    // Feature manager in the menu bar panel
    let managerInstalledTab: String
    let managerAllTab: String
    let managerIntro: String
    let managerEmpty: String
    let managerOpenHub: String
    let managerSettingsHelp: String
    // Setup tour
    let tourTitle: String
    let tourSubtitle: String
    let tourMenuBarTitle: String
    let tourMenuBarBody: String
    let tourTabsTitle: String
    let tourTabsBody: String
    let tourFeaturesTitle: String
    let tourFeaturesBody: String
    let tourSettingsTitle: String
    let tourSettingsBody: String
    let tourStepFormat: String        // "Step %1$d of %2$d"
    let tourSkip: String
}

extension FeatureStrings {
    static func tour(_ language: AppLanguage) -> TourStrings {
        switch language {
        case .enUS: return .enUS
        case .ptBR: return .ptBR
        case .tr: return .tr
        case .ru: return .ru
        case .es: return .es
        case .sk: return .sk
        case .de: return .de
        case .fr: return .fr
        case .it: return .it
        case .ja: return .ja
        case .ko: return .ko
        case .zhHans: return .zhHans
        case .zhTW: return .zhTW
        case .zhHK: return .zhHK
        case .uk: return .uk
        }
    }
}

extension TourStrings {
    static let enUS = TourStrings(
        managerInstalledTab: "Installed",
        managerAllTab: "All",
        managerIntro: "Switch any feature on or off right here. The gear opens its settings.",
        managerEmpty: "Nothing installed yet. Switch to All to add features.",
        managerOpenHub: "All features in Settings",
        managerSettingsHelp: "Open settings",
        tourTitle: "A quick tour",
        tourSubtitle: "Here is where everything lives in Furoshiki. Click through the steps.",
        tourMenuBarTitle: "The bundle in your menu bar",
        tourMenuBarBody: "Furoshiki lives at the top right of your menu bar. Click it to open the window with your tools. Right-click it for a short menu.",
        tourTabsTitle: "Your tools behind the icons",
        tourTabsBody: "Each icon at the top of the window is one area, such as sound, the monitor or your tools. Click an icon to switch.",
        tourFeaturesTitle: "Manage features",
        tourFeaturesBody: "Features at the bottom of the window lists everything Furoshiki can do. Switch each feature on or off, and use the gear to set it up.",
        tourSettingsTitle: "Fine-tune everything",
        tourSettingsBody: "Settings opens the big window with every option, shortcut and permission. You can watch this introduction again there at any time.",
        tourStepFormat: "Step %1$d of %2$d",
        tourSkip: "Skip tour"
    )

    static let ptBR = TourStrings(
        managerInstalledTab: "Instalados",
        managerAllTab: "Todos",
        managerIntro: "Ative ou desative qualquer recurso aqui mesmo. A engrenagem abre os ajustes dele.",
        managerEmpty: "Nada instalado ainda. Mude para Todos para adicionar recursos.",
        managerOpenHub: "Todos os recursos nos Ajustes",
        managerSettingsHelp: "Abrir ajustes",
        tourTitle: "Um tour rápido",
        tourSubtitle: "Veja onde fica cada coisa no Furoshiki. Clique pelos passos.",
        tourMenuBarTitle: "A trouxinha na barra de menus",
        tourMenuBarBody: "O Furoshiki fica no canto superior direito da barra de menus. Clique para abrir a janela com suas ferramentas. Clique com o botão direito para ver um menu curto.",
        tourTabsTitle: "Suas ferramentas atrás dos ícones",
        tourTabsBody: "Cada ícone no topo da janela é uma área, como som, monitor ou ferramentas. Clique em um ícone para trocar.",
        tourFeaturesTitle: "Gerenciar recursos",
        tourFeaturesBody: "Recursos, na parte de baixo da janela, lista tudo o que o Furoshiki faz. Ative ou desative cada recurso e use a engrenagem para configurá-lo.",
        tourSettingsTitle: "Ajuste cada detalhe",
        tourSettingsBody: "Ajustes abre a janela grande com todas as opções, atalhos e permissões. Lá você pode rever esta introdução quando quiser.",
        tourStepFormat: "Passo %1$d de %2$d",
        tourSkip: "Pular tour"
    )

    static let tr = TourStrings(
        managerInstalledTab: "Yüklü",
        managerAllTab: "Tümü",
        managerIntro: "Herhangi bir özelliği buradan açıp kapatın. Dişli simgesi ayarlarını açar.",
        managerEmpty: "Henüz bir şey yüklü değil. Özellik eklemek için Tümü sekmesine geçin.",
        managerOpenHub: "Ayarlar’da tüm özellikler",
        managerSettingsHelp: "Ayarları aç",
        tourTitle: "Kısa bir tur",
        tourSubtitle: "Furoshiki’de her şeyin nerede olduğunu görün. Adımlara tıklayarak ilerleyin.",
        tourMenuBarTitle: "Menü çubuğundaki bohça",
        tourMenuBarBody: "Furoshiki menü çubuğunun sağ üstünde durur. Araçlarınızın olduğu pencereyi açmak için tıklayın. Kısa bir menü için sağ tıklayın.",
        tourTabsTitle: "Araçlarınız simgelerin arkasında",
        tourTabsBody: "Pencerenin üstündeki her simge bir alandır: ses, monitör veya araçlar gibi. Geçiş yapmak için bir simgeye tıklayın.",
        tourFeaturesTitle: "Özellikleri yönetin",
        tourFeaturesBody: "Pencerenin altındaki Özellikler, Furoshiki’nin yapabildiği her şeyi listeler. Her özelliği açıp kapatın, ayarlamak için dişliyi kullanın.",
        tourSettingsTitle: "Her şeyi ince ayarlayın",
        tourSettingsBody: "Ayarlar; tüm seçenekleri, kısayolları ve izinleri içeren büyük pencereyi açar. Bu tanıtımı orada istediğiniz zaman yeniden izleyebilirsiniz.",
        tourStepFormat: "Adım %1$d / %2$d",
        tourSkip: "Turu atla"
    )

    static let ru = TourStrings(
        managerInstalledTab: "Установленные",
        managerAllTab: "Все",
        managerIntro: "Включайте и выключайте любую функцию прямо здесь. Шестерёнка открывает её настройки.",
        managerEmpty: "Пока ничего не установлено. Откройте «Все», чтобы добавить функции.",
        managerOpenHub: "Все функции в настройках",
        managerSettingsHelp: "Открыть настройки",
        tourTitle: "Короткая экскурсия",
        tourSubtitle: "Вот где что находится в Furoshiki. Пройдите по шагам.",
        tourMenuBarTitle: "Узелок в строке меню",
        tourMenuBarBody: "Furoshiki живёт в правом верхнем углу строки меню. Нажмите на него, чтобы открыть окно с инструментами. Правый клик открывает короткое меню.",
        tourTabsTitle: "Инструменты за значками",
        tourTabsBody: "Каждый значок вверху окна открывает отдельный раздел, например звук, монитор или инструменты. Нажмите на значок, чтобы переключиться.",
        tourFeaturesTitle: "Управление функциями",
        tourFeaturesBody: "Кнопка «Функции» внизу окна показывает всё, что умеет Furoshiki. Включайте и выключайте функции, а шестерёнка открывает их настройки.",
        tourSettingsTitle: "Тонкая настройка",
        tourSettingsBody: "«Настройки» открывают большое окно со всеми параметрами, сочетаниями клавиш и разрешениями. Там же можно снова посмотреть это введение.",
        tourStepFormat: "Шаг %1$d из %2$d",
        tourSkip: "Пропустить"
    )

    static let es = TourStrings(
        managerInstalledTab: "Instaladas",
        managerAllTab: "Todas",
        managerIntro: "Activa o desactiva cualquier función aquí mismo. El engranaje abre sus ajustes.",
        managerEmpty: "Aún no hay nada instalado. Cambia a Todas para añadir funciones.",
        managerOpenHub: "Todas las funciones en Ajustes",
        managerSettingsHelp: "Abrir ajustes",
        tourTitle: "Un recorrido rápido",
        tourSubtitle: "Así encuentras cada cosa en Furoshiki. Avanza paso a paso.",
        tourMenuBarTitle: "El hatillo en la barra de menús",
        tourMenuBarBody: "Furoshiki vive arriba a la derecha en la barra de menús. Haz clic para abrir la ventana con tus herramientas. Con clic derecho aparece un menú corto.",
        tourTabsTitle: "Tus herramientas tras los iconos",
        tourTabsBody: "Cada icono en la parte superior de la ventana es un área, como sonido, monitor o herramientas. Haz clic en un icono para cambiar.",
        tourFeaturesTitle: "Gestionar funciones",
        tourFeaturesBody: "Funciones, abajo en la ventana, muestra todo lo que hace Furoshiki. Activa o desactiva cada función y usa el engranaje para configurarla.",
        tourSettingsTitle: "Ajusta cada detalle",
        tourSettingsBody: "Ajustes abre la ventana grande con todas las opciones, atajos y permisos. Ahí puedes volver a ver esta introducción cuando quieras.",
        tourStepFormat: "Paso %1$d de %2$d",
        tourSkip: "Saltar recorrido"
    )

    static let sk = TourStrings(
        managerInstalledTab: "Nainštalované",
        managerAllTab: "Všetky",
        managerIntro: "Zapni alebo vypni ktorúkoľvek funkciu priamo tu. Ozubené koliesko otvorí jej nastavenia.",
        managerEmpty: "Zatiaľ nie je nič nainštalované. Prepni na Všetky a pridaj funkcie.",
        managerOpenHub: "Všetky funkcie v nastaveniach",
        managerSettingsHelp: "Otvoriť nastavenia",
        tourTitle: "Krátka prehliadka",
        tourSubtitle: "Takto sa vyznáš vo Furoshiki. Preklikaj sa krokmi.",
        tourMenuBarTitle: "Uzlík na lište menu",
        tourMenuBarBody: "Furoshiki býva vpravo hore na lište menu. Kliknutím otvoríš okno so svojimi nástrojmi. Pravým kliknutím zobrazíš krátke menu.",
        tourTabsTitle: "Nástroje za ikonami",
        tourTabsBody: "Každá ikona hore v okne je jedna oblasť, napríklad zvuk, monitor alebo nástroje. Kliknutím na ikonu prepneš.",
        tourFeaturesTitle: "Správa funkcií",
        tourFeaturesBody: "Funkcie dole v okne ukazujú všetko, čo Furoshiki dokáže. Každú funkciu zapneš alebo vypneš a ozubeným kolieskom ju nastavíš.",
        tourSettingsTitle: "Všetko dolaď",
        tourSettingsBody: "Nastavenia otvoria veľké okno so všetkými možnosťami, skratkami a povoleniami. Tam si môžeš tento úvod kedykoľvek pozrieť znova.",
        tourStepFormat: "Krok %1$d z %2$d",
        tourSkip: "Preskočiť prehliadku"
    )

    static let de = TourStrings(
        managerInstalledTab: "Installiert",
        managerAllTab: "Alle",
        managerIntro: "Schalte jede Funktion direkt hier ein oder aus. Das Zahnrad öffnet ihre Einstellungen.",
        managerEmpty: "Noch nichts installiert. Wechsle zu Alle, um Funktionen hinzuzufügen.",
        managerOpenHub: "Alle Funktionen in den Einstellungen",
        managerSettingsHelp: "Einstellungen öffnen",
        tourTitle: "Ein kurzer Rundgang",
        tourSubtitle: "So findest du dich in Furoshiki zurecht. Klicke dich durch die Schritte.",
        tourMenuBarTitle: "Das Tuchbündel in der Menüleiste",
        tourMenuBarBody: "Furoshiki wohnt oben rechts in deiner Menüleiste. Ein Klick öffnet das Fenster mit deinen Werkzeugen, ein Rechtsklick zeigt ein kurzes Menü.",
        tourTabsTitle: "Deine Werkzeuge hinter den Symbolen",
        tourTabsBody: "Jedes Symbol oben im Fenster ist ein Bereich, zum Beispiel Ton, Monitor oder Werkzeuge. Klicke auf ein Symbol, um zu wechseln.",
        tourFeaturesTitle: "Funktionen verwalten",
        tourFeaturesBody: "Funktionen unten im Fenster zeigt alles, was Furoshiki kann. Schalte jede Funktion ein oder aus und richte sie über das Zahnrad ein.",
        tourSettingsTitle: "Alles feiner einstellen",
        tourSettingsBody: "Einstellungen öffnet das große Fenster mit allen Optionen, Kurzbefehlen und Berechtigungen. Dort kannst du diese Einführung jederzeit erneut ansehen.",
        tourStepFormat: "Schritt %1$d von %2$d",
        tourSkip: "Rundgang überspringen"
    )

    static let fr = TourStrings(
        managerInstalledTab: "Installées",
        managerAllTab: "Toutes",
        managerIntro: "Activez ou désactivez n’importe quelle fonction ici même. La roue dentée ouvre ses réglages.",
        managerEmpty: "Rien n’est encore installé. Passez à Toutes pour ajouter des fonctions.",
        managerOpenHub: "Toutes les fonctions dans les Réglages",
        managerSettingsHelp: "Ouvrir les réglages",
        tourTitle: "Petite visite guidée",
        tourSubtitle: "Voici où tout se trouve dans Furoshiki. Avancez étape par étape.",
        tourMenuBarTitle: "Le baluchon dans la barre des menus",
        tourMenuBarBody: "Furoshiki se trouve en haut à droite de la barre des menus. Cliquez dessus pour ouvrir la fenêtre avec vos outils. Un clic droit affiche un court menu.",
        tourTabsTitle: "Vos outils derrière les icônes",
        tourTabsBody: "Chaque icône en haut de la fenêtre est une zone, comme le son, le moniteur ou les outils. Cliquez sur une icône pour changer.",
        tourFeaturesTitle: "Gérer les fonctions",
        tourFeaturesBody: "Fonctions, en bas de la fenêtre, liste tout ce que Furoshiki sait faire. Activez ou désactivez chaque fonction et réglez-la avec la roue dentée.",
        tourSettingsTitle: "Tout régler en détail",
        tourSettingsBody: "Réglages ouvre la grande fenêtre avec toutes les options, tous les raccourcis et toutes les autorisations. Vous pouvez y revoir cette introduction à tout moment.",
        tourStepFormat: "Étape %1$d sur %2$d",
        tourSkip: "Passer la visite"
    )

    static let it = TourStrings(
        managerInstalledTab: "Installate",
        managerAllTab: "Tutte",
        managerIntro: "Attiva o disattiva qualsiasi funzione proprio qui. L’ingranaggio apre le sue impostazioni.",
        managerEmpty: "Ancora nulla di installato. Passa a Tutte per aggiungere funzioni.",
        managerOpenHub: "Tutte le funzioni nelle Impostazioni",
        managerSettingsHelp: "Apri impostazioni",
        tourTitle: "Un breve tour",
        tourSubtitle: "Ecco dove si trova ogni cosa in Furoshiki. Procedi un passo alla volta.",
        tourMenuBarTitle: "Il fagotto nella barra dei menu",
        tourMenuBarBody: "Furoshiki vive in alto a destra nella barra dei menu. Fai clic per aprire la finestra con i tuoi strumenti. Con il clic destro compare un breve menu.",
        tourTabsTitle: "I tuoi strumenti dietro le icone",
        tourTabsBody: "Ogni icona in cima alla finestra è un’area, come audio, monitor o strumenti. Fai clic su un’icona per passare da una all’altra.",
        tourFeaturesTitle: "Gestisci le funzioni",
        tourFeaturesBody: "Funzioni, in fondo alla finestra, elenca tutto ciò che Furoshiki sa fare. Attiva o disattiva ogni funzione e configurala con l’ingranaggio.",
        tourSettingsTitle: "Regola ogni dettaglio",
        tourSettingsBody: "Impostazioni apre la finestra grande con tutte le opzioni, le scorciatoie e i permessi. Lì puoi rivedere questa introduzione quando vuoi.",
        tourStepFormat: "Passo %1$d di %2$d",
        tourSkip: "Salta il tour"
    )

    static let ja = TourStrings(
        managerInstalledTab: "インストール済み",
        managerAllTab: "すべて",
        managerIntro: "ここで各機能をオン・オフできます。歯車アイコンで設定を開きます。",
        managerEmpty: "まだ何もインストールされていません。「すべて」から機能を追加できます。",
        managerOpenHub: "設定ですべての機能を表示",
        managerSettingsHelp: "設定を開く",
        tourTitle: "かんたんツアー",
        tourSubtitle: "Furoshiki のどこに何があるかを紹介します。順番にクリックしてください。",
        tourMenuBarTitle: "メニューバーの包み",
        tourMenuBarBody: "Furoshiki はメニューバーの右上にあります。クリックするとツールのウインドウが開き、右クリックで短いメニューが表示されます。",
        tourTabsTitle: "アイコンの先にあるツール",
        tourTabsBody: "ウインドウ上部のアイコンはそれぞれ、サウンド、モニタ、ツールなどの領域です。アイコンをクリックして切り替えます。",
        tourFeaturesTitle: "機能を管理する",
        tourFeaturesBody: "ウインドウ下部の「機能」に、Furoshiki でできることがすべて並んでいます。各機能をオン・オフし、歯車アイコンで設定します。",
        tourSettingsTitle: "細かく調整する",
        tourSettingsBody: "「設定」を押すと、すべてのオプション、ショートカット、アクセス権がそろった大きなウインドウが開きます。この紹介もそこからいつでも見直せます。",
        tourStepFormat: "ステップ %1$d / %2$d",
        tourSkip: "ツアーをスキップ"
    )

    static let ko = TourStrings(
        managerInstalledTab: "설치됨",
        managerAllTab: "전체",
        managerIntro: "여기서 바로 기능을 켜거나 끌 수 있습니다. 톱니바퀴를 누르면 설정이 열립니다.",
        managerEmpty: "아직 설치된 기능이 없습니다. 전체로 전환해 기능을 추가하세요.",
        managerOpenHub: "설정에서 모든 기능 보기",
        managerSettingsHelp: "설정 열기",
        tourTitle: "간단한 둘러보기",
        tourSubtitle: "Furoshiki에서 무엇이 어디에 있는지 알려 드립니다. 단계별로 클릭해 보세요.",
        tourMenuBarTitle: "메뉴 막대의 보자기",
        tourMenuBarBody: "Furoshiki는 메뉴 막대 오른쪽 위에 있습니다. 클릭하면 도구 창이 열리고, 오른쪽 클릭하면 짧은 메뉴가 나타납니다.",
        tourTabsTitle: "아이콘 뒤에 있는 도구",
        tourTabsBody: "창 위쪽의 각 아이콘은 사운드, 모니터, 도구 같은 하나의 영역입니다. 아이콘을 클릭해 전환하세요.",
        tourFeaturesTitle: "기능 관리",
        tourFeaturesBody: "창 아래쪽의 기능에서 Furoshiki가 할 수 있는 모든 것을 볼 수 있습니다. 각 기능을 켜거나 끄고 톱니바퀴로 설정하세요.",
        tourSettingsTitle: "세부 조정",
        tourSettingsBody: "설정을 누르면 모든 옵션, 단축키, 권한이 있는 큰 창이 열립니다. 이 소개도 그곳에서 언제든 다시 볼 수 있습니다.",
        tourStepFormat: "%2$d단계 중 %1$d단계",
        tourSkip: "둘러보기 건너뛰기"
    )

    static let zhHans = TourStrings(
        managerInstalledTab: "已安装",
        managerAllTab: "全部",
        managerIntro: "在这里直接开启或关闭任何功能。齿轮按钮会打开它的设置。",
        managerEmpty: "尚未安装任何功能。切换到“全部”即可添加功能。",
        managerOpenHub: "在设置中查看全部功能",
        managerSettingsHelp: "打开设置",
        tourTitle: "快速导览",
        tourSubtitle: "看看 Furoshiki 中各项内容都在哪里。逐步点击浏览。",
        tourMenuBarTitle: "菜单栏中的小包袱",
        tourMenuBarBody: "Furoshiki 位于菜单栏右上角。点按即可打开工具窗口，右键点按会显示一个简短菜单。",
        tourTabsTitle: "图标背后的工具",
        tourTabsBody: "窗口顶部的每个图标都是一个区域，例如声音、监视器或工具。点按图标即可切换。",
        tourFeaturesTitle: "管理功能",
        tourFeaturesBody: "窗口底部的“功能”列出了 Furoshiki 能做的一切。逐个开启或关闭功能，并用齿轮按钮进行设置。",
        tourSettingsTitle: "细致调整",
        tourSettingsBody: "“设置”会打开包含所有选项、快捷键和权限的大窗口。你也可以随时在那里重新查看这份介绍。",
        tourStepFormat: "第 %1$d 步，共 %2$d 步",
        tourSkip: "跳过导览"
    )

    static let zhTW = TourStrings(
        managerInstalledTab: "已安裝",
        managerAllTab: "全部",
        managerIntro: "在這裡直接開啟或關閉任何功能。齒輪按鈕會打開它的設定。",
        managerEmpty: "尚未安裝任何功能。切換到「全部」即可加入功能。",
        managerOpenHub: "在設定中檢視全部功能",
        managerSettingsHelp: "打開設定",
        tourTitle: "快速導覽",
        tourSubtitle: "看看 Furoshiki 中各項內容都在哪裡。逐步點按瀏覽。",
        tourMenuBarTitle: "選單列中的小包袱",
        tourMenuBarBody: "Furoshiki 位於選單列右上角。點按即可打開工具視窗，按右鍵會顯示一個簡短選單。",
        tourTabsTitle: "圖示背後的工具",
        tourTabsBody: "視窗頂部的每個圖示都是一個區域，例如聲音、監視器或工具。點按圖示即可切換。",
        tourFeaturesTitle: "管理功能",
        tourFeaturesBody: "視窗底部的「功能」列出了 Furoshiki 能做的一切。逐一開啟或關閉功能，並用齒輪按鈕進行設定。",
        tourSettingsTitle: "細部調整",
        tourSettingsBody: "「設定」會打開包含所有選項、快速鍵和權限的大視窗。你也可以隨時在那裡重新檢視這份介紹。",
        tourStepFormat: "第 %1$d 步，共 %2$d 步",
        tourSkip: "略過導覽"
    )

    static let zhHK = TourStrings(
        managerInstalledTab: "已安裝",
        managerAllTab: "全部",
        managerIntro: "喺呢度直接開啟或關閉任何功能。齒輪按鈕會打開佢嘅設定。",
        managerEmpty: "仲未安裝任何功能。切換到「全部」就可以加入功能。",
        managerOpenHub: "喺設定中檢視全部功能",
        managerSettingsHelp: "打開設定",
        tourTitle: "快速導覽",
        tourSubtitle: "睇吓 Furoshiki 入面各樣嘢喺邊度。逐步點按瀏覽。",
        tourMenuBarTitle: "選單列中嘅小包袱",
        tourMenuBarBody: "Furoshiki 喺選單列右上角。點按就會打開工具視窗，按右鍵會顯示一個簡短選單。",
        tourTabsTitle: "圖示背後嘅工具",
        tourTabsBody: "視窗頂部每個圖示都係一個區域，例如聲音、監視器或者工具。點按圖示就可以切換。",
        tourFeaturesTitle: "管理功能",
        tourFeaturesBody: "視窗底部嘅「功能」列出咗 Furoshiki 做得到嘅一切。逐一開啟或關閉功能，再用齒輪按鈕設定。",
        tourSettingsTitle: "細部調整",
        tourSettingsBody: "「設定」會打開包含所有選項、快速鍵同權限嘅大視窗。你亦可以隨時喺嗰度重新睇返呢份介紹。",
        tourStepFormat: "第 %1$d 步，共 %2$d 步",
        tourSkip: "略過導覽"
    )

    static let uk = TourStrings(
        managerInstalledTab: "Встановлені",
        managerAllTab: "Усі",
        managerIntro: "Вмикайте й вимикайте будь-яку функцію просто тут. Шестірня відкриває її налаштування.",
        managerEmpty: "Поки нічого не встановлено. Відкрийте «Усі», щоб додати функції.",
        managerOpenHub: "Усі функції в налаштуваннях",
        managerSettingsHelp: "Відкрити налаштування",
        tourTitle: "Коротка екскурсія",
        tourSubtitle: "Ось де що є у Furoshiki. Пройдіть кроками.",
        tourMenuBarTitle: "Вузлик у рядку меню",
        tourMenuBarBody: "Furoshiki живе в правому верхньому куті рядка меню. Натисніть на нього, щоб відкрити вікно з інструментами. Правий клік показує коротке меню.",
        tourTabsTitle: "Інструменти за значками",
        tourTabsBody: "Кожен значок угорі вікна відкриває окремий розділ, наприклад звук, монітор чи інструменти. Натисніть на значок, щоб перемкнутися.",
        tourFeaturesTitle: "Керування функціями",
        tourFeaturesBody: "Кнопка «Функції» внизу вікна показує все, що вміє Furoshiki. Вмикайте й вимикайте функції, а шестірня відкриває їхні налаштування.",
        tourSettingsTitle: "Точне налаштування",
        tourSettingsBody: "«Налаштування» відкривають велике вікно з усіма параметрами, скороченнями й дозволами. Там можна будь-коли знову переглянути це введення.",
        tourStepFormat: "Крок %1$d з %2$d",
        tourSkip: "Пропустити"
    )
}
