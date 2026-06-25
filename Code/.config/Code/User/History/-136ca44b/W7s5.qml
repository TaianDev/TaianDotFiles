import Quickshell
import Quickshell.Io
import QtQuick 
import QtQuick.Layouts
import QtQuick.Controls

PanelWindow {
    id: principalPanel
    color: "transparent"
    focusable: true
    anchors {
        left: false; right: false; top: false; bottom: false
    }
    implicitWidth: principalPanel.screen.width * 0.25
    implicitHeight: principalPanel.screen.height * 0.23

    // Buffer
    property var textToTranslate: ""

    // Language codes mapping
    function getLangCode(langName) {
        let langs = {
            "Automatic detection": "auto",
            "Afrikaans": "af",
            "Albanian": "sq",
            "Amharic": "am",
            "Arabic": "ar",
            "Armenian": "hy",
            "Assamese": "as",
            "Aymara": "ay",
            "Azerbaijani": "az",
            "Bambara": "bm",
            "Bashkir": "ba",
            "Basque": "eu",
            "Belarusian": "be",
            "Bengali": "bn",
            "Bhojpuri": "bho",
            "Bosnian": "bs",
            "Bulgarian": "bg",
            "Catalan": "ca",
            "Cebuano": "ceb",
            "Central Kurdish": "ckb",
            "Chavacano": "cbk",
            "Cherokee": "chr",
            "Chewa": "ny",
            "Chinese (Simplified)": "zh-CN",
            "Chinese (Traditional)": "zh-TW",
            "Chuvash": "cv",
            "Corsican": "co",
            "Croatian": "hr",
            "Czech": "cs",
            "Danish": "da",
            "Dhivehi": "dv",
            "Dogri": "doi",
            "Dutch": "nl",
            "English": "en",
            "Esperanto": "eo",
            "Estonian": "et",
            "Ewe": "ee",
            "Faroese": "fo",
            "Fijian": "fj",
            "Filipino": "tl",
            "Finnish": "fi",
            "French": "fr",
            "French (Canada)": "fr-CA",
            "Frisian": "fy",
            "Galician": "gl",
            "Georgian": "ka",
            "German": "de",
            "Goan Konkani": "gom",
            "Greek": "el",
            "Guarani": "gn",
            "Gujarati": "gu",
            "Haitian Creole": "ht",
            "Hausa": "ha",
            "Hawaiian": "haw",
            "Hebrew": "he",
            "Hill Mari": "mrj",
            "Hindi": "hi",
            "Hmong": "hmn",
            "Hungarian": "hu",
            "Icelandic": "is",
            "Igbo": "ig",
            "Iloko": "ilo",
            "Indonesian": "id",
            "Inuinnaqtun": "ikt",
            "Inuktitut": "iu",
            "Inuktitut (Latin)": "iu-Latn",
            "Irish": "ga",
            "Italian": "it",
            "Japanese": "ja",
            "Javanese": "jv",
            "Kannada": "kn",
            "Kazakh": "kk",
            "Khmer": "km",
            "Kinyarwanda": "rw",
            "Klingon (Latin)": "tlh-Latn",
            "Korean": "ko",
            "Krio": "kri",
            "Kurdish": "ku",
            "Kyrgyz": "ky",
            "Lao": "lo",
            "Latin": "la",
            "Latvian": "lv",
            "Lingala": "ln",
            "Lithuanian": "lt",
            "Literary Chinese": "lzh",
            "Luganda": "lg",
            "Luxembourgish": "lb",
            "Macedonian": "mk",
            "Maithili": "mai",
            "Malagasy": "mg",
            "Malay": "ms",
            "Malayalam": "ml",
            "Maltese": "mt",
            "Manipuri (Meitei Mayek)": "mni-Mtei",
            "Maori": "mi",
            "Marathi": "mr",
            "Meadow Mari": "mhr",
            "Min Nan Chinese": "nan",
            "Mizo": "lus",
            "Mongolian": "mn",
            "Mongolian (Traditional)": "mn-Mong",
            "Myanmar (Burmese)": "my",
            "Nepali": "ne",
            "Northern Sotho": "nso",
            "Norwegian": "no",
            "Odia (Oriya)": "or",
            "Oromo": "om",
            "Otomi (Querétaro)": "otq",
            "Papiamento": "pap",
            "Pashto": "ps",
            "Persian": "fa",
            "Polish": "pl",
            "Portuguese (Brazil)": "pt-BR",
            "Portuguese (Portugal)": "pt-PT",
            "Punjabi": "pa",
            "Quechua": "qu",
            "Romanian": "ro",
            "Russian": "ru",
            "Samoan": "sm",
            "Sanskrit": "sa",
            "Scots Gaelic": "gd",
            "Serbian (Cyrillic)": "sr-Cyrl",
            "Serbian (Latin)": "sr-Latn",
            "Shona": "sn",
            "Sindhi": "sd",
            "Sinhala": "si",
            "Slovak": "sk",
            "Slovenian": "sl",
            "Somali": "so",
            "Southern Sotho": "st",
            "Spanish": "es",
            "Sundanese": "su",
            "Swahili": "sw",
            "Swedish": "sv",
            "Tagalog": "tl",
            "Tajik": "tg",
            "Tamil": "ta",
            "Tatar": "tt",
            "Telugu": "te",
            "Thai": "th",
            "Tibetan": "bo",
            "Tigrinya": "ti",
            "Tlingit": "tli",
            "Tonga": "to",
            "Tsonga": "ts",
            "Turkish": "tr",
            "Turkmen": "tk",
            "Twi": "tw",
            "Tahitian": "ty",
            "Udmurt": "udm",
            "Uyghur": "ug",
            "Ukrainian": "uk",
            "Urdu": "ur",
            "Uzbek": "uz",
            "Vietnamese": "vi",
            "Welsh": "cy",
            "Xhosa": "xh",
            "Yiddish": "yi",
            "Yoruba": "yo",
            "Yucatec Maya": "yua",
            "Cantonese": "yue",
            "Zulu": "zu"
        }
        return langs[langName] || "auto"
    }

    // Engine codes mapping
    function getEngineCode(engineName) {
        let engines = {
            "Google": "google",
            "Bing": "bing",
            "Yandex": "yandex"
        }
        return engines[engineName] || "google"
    }

    // Logical part
    Process {
        id: lectorBuffer
        command: ["cat", "/tmp/translate_buffer_input.txt"]
        running: true 
        
        stdout: StdioCollector {
            onStreamFinished: {
                principalPanel.textToTranslate = this.text
                backendTraductor.running = true 
            }
        }
    }

    Process {
        id: backendTraductor
        running: false
        command: [ 
            "bash", 
            "/home/taianlux/.config/quickshell/Translate/scripts/translate.sh", 
            getLangCode(sourceLanguageSelector.optionsList[sourceLanguageSelector.currentText]), // Source language code
            getLangCode(targetLanguageSelector.optionsList[targetLanguageSelector.currentText]), // Target language code
            getEngineCode(translationEngineSelector.optionsList[translationEngineSelector.currentText]), // Engine code
            principalPanel.textToTranslate // Text to translate
        ]
        
        stdout: StdioCollector {
            onStreamFinished: {
                textToTranslateArea.text = this.text
            }
        }
    }

    Rectangle {
        id: topPanel
        anchors.fill: parent
        radius: topPanel.height * 0.06
        color: "#ffffff"
        
        ColumnLayout {
            anchors.fill: parent
            anchors.margins: topPanel.width * 0.03
            spacing: topPanel.height * 0.06 
        
            RowLayout {
                Layout.fillWidth: true 
                spacing: topPanel.width * 0.03

                SelectorTranslate {
                    id: sourceLanguageSelector
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    optionsList: [
                        "Automatic detection", "Afrikaans", "Albanian", "Amharic", "Arabic", "Armenian", "Assamese", "Aymara", "Azerbaijani", "Bambara", "Bashkir", "Basque", "Belarusian", "Bengali", "Bhojpuri", "Bosnian", "Bulgarian", "Catalan", "Cebuano", "Central Kurdish", "Chavacano", "Cherokee", "Chewa", "Chinese (Simplified)", "Chinese (Traditional)", "Chuvash", "Corsican", "Croatian", "Czech", "Danish", "Dhivehi", "Dogri", "Dutch", "English", "Esperanto", "Estonian", "Ewe", "Faroese", "Fijian", "Filipino", "Finnish", "French", "French (Canada)", "Frisian", "Galician", "Georgian", "German", "Goan Konkani", "Greek", "Guarani", "Gujarati", "Haitian Creole", "Hausa", "Hawaiian", "Hebrew", "Hill Mari", "Hindi", "Hmong", "Hungarian", "Icelandic", "Igbo", "Iloko", "Indonesian", "Inuinnaqtun", "Inuktitut", "Inuktitut (Latin)", "Irish", "Italian", "Japanese", "Javanese", "Kannada", "Kazakh", "Khmer", "Kinyarwanda", "Klingon (Latin)", "Korean", "Krio", "Kurdish", "Kyrgyz", "Lao", "Latin", "Latvian", "Lingala", "Lithuanian", "Literary Chinese", "Luganda", "Luxembourgish", "Macedonian", "Maithili", "Malagasy", "Malay", "Malayalam", "Maltese", "Manipuri (Meitei Mayek)", "Maori", "Marathi", "Meadow Mari", "Min Nan Chinese", "Mizo", "Mongolian", "Mongolian (Traditional)", "Myanmar (Burmese)", "Nepali", "Northern Sotho", "Norwegian", "Odia (Oriya)", "Oromo", "Otomi (Querétaro)", "Papiamento", "Pashto", "Persian", "Polish", "Portuguese (Brazil)", "Portuguese (Portugal)", "Punjabi", "Quechua", "Romanian", "Russian", "Samoan", "Sanskrit", "Scots Gaelic", "Serbian (Cyrillic)", "Serbian (Latin)", "Shona", "Sindhi", "Sinhala", "Slovak", "Slovenian", "Somali", "Southern Sotho", "Spanish", "Sundanese", "Swahili", "Swedish", "Tagalog", "Tajik", "Tamil", "Tatar", "Telugu", "Thai", "Tibetan", "Tigrinya", "Tlingit", "Tonga", "Tsonga", "Turkish", "Turkmen", "Twi", "Tahitian", "Udmurt", "Uyghur", "Ukrainian", "Urdu", "Uzbek", "Vietnamese", "Welsh", "Xhosa", "Yiddish", "Yoruba", "Yucatec Maya", "Cantonese", "Zulu"
                    ]
                }

                Rectangle {
                    id: languageSwitcher
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.1
                    radius: topPanel.height * 0.03
                    color: '#8cf0c3'
                }

                SelectorTranslate {
                    id: targetLanguageSelector
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    optionsList: [
                        "Spanish", "Afrikaans", "Albanian", "Amharic", "Arabic", "Armenian", "Assamese", "Automatic detection", "Aymara", "Azerbaijani", "Bambara", "Bashkir", "Basque", "Belarusian", "Bengali", "Bhojpuri", "Bosnian", "Bulgarian", "Catalan", "Cebuano", "Central Kurdish", "Chavacano", "Cherokee", "Chewa", "Chinese (Simplified)", "Chinese (Traditional)", "Chuvash", "Corsican", "Croatian", "Czech", "Danish", "Dhivehi", "Dogri", "Dutch", "English", "Esperanto", "Estonian", "Ewe", "Faroese", "Fijian", "Filipino", "Finnish", "French", "French (Canada)", "Frisian", "Galician", "Georgian", "German", "Goan Konkani", "Greek", "Guarani", "Gujarati", "Haitian Creole", "Hausa", "Hawaiian", "Hebrew", "Hill Mari", "Hindi", "Hmong", "Hungarian", "Icelandic", "Igbo", "Iloko", "Indonesian", "Inuinnaqtun", "Inuktitut", "Inuktitut (Latin)", "Irish", "Italian", "Japanese", "Javanese", "Kannada", "Kazakh", "Khmer", "Kinyarwanda", "Klingon (Latin)", "Korean", "Krio", "Kurdish", "Kyrgyz", "Lao", "Latin", "Latvian", "Lingala", "Lithuanian", "Literary Chinese", "Luganda", "Luxembourgish", "Macedonian", "Maithili", "Malagasy", "Malay", "Malayalam", "Maltese", "Manipuri (Meitei Mayek)", "Maori", "Marathi", "Meadow Mari", "Min Nan Chinese", "Mizo", "Mongolian", "Mongolian (Traditional)", "Myanmar (Burmese)", "Nepali", "Northern Sotho", "Norwegian", "Odia (Oriya)", "Oromo", "Otomi (Querétaro)", "Papiamento", "Pashto", "Persian", "Polish", "Portuguese (Brazil)", "Portuguese (Portugal)", "Punjabi", "Quechua", "Romanian", "Russian", "Samoan", "Sanskrit", "Scots Gaelic", "Serbian (Cyrillic)", "Serbian (Latin)", "Shona", "Sindhi", "Sinhala", "Slovak", "Slovenian", "Somali", "Southern Sotho", "Sundanese", "Swahili", "Swedish", "Tagalog", "Tajik", "Tamil", "Tatar", "Telugu", "Thai", "Tibetan", "Tigrinya", "Tlingit", "Tonga", "Tsonga", "Turkish", "Turkmen", "Twi", "Tahitian", "Udmurt", "Uyghur", "Ukrainian", "Urdu", "Uzbek", "Vietnamese", "Welsh", "Xhosa", "Yiddish", "Yoruba", "Yucatec Maya", "Cantonese", "Zulu"
                    ]
                }

                SelectorTranslate {
                    id: translationEngineSelector
                    Layout.alignment: Qt.AlignTop | Qt.AlignLeft
                    Layout.preferredHeight: topPanel.height * 0.19
                    Layout.preferredWidth: topPanel.width * 0.25
                    optionsList: ["Google", "Bing", "Yandex"]
                }
            }
            
            Rectangle {
                id: translateTextWindow
                Layout.fillWidth: true  
                Layout.fillHeight: true 
                radius: topPanel.height * 0.03
                color: '#8cf0c3'
                ScrollView {
                    anchors.fill: parent
                    anchors.margins: topPanel.width * 0.03
                    TextArea {
                        id: textToTranslateArea
                        readOnly: true 
                        selectByMouse: true 
                        wrapMode: TextArea.Wrap
                        placeholderText: "Here will appear the translated text :D"
                        background: null 
                        color: "#1e1e2e" 
                    }
                }
            }
        }
    }
}