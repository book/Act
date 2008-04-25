package Act::Language;
use strict;
use utf8;

# http://www.loc.gov/standards/iso639-2/langhome.html
my %LANGUAGES = (
aa => "Afaraf",                             # Afar
ab => "Аҧсуа",                              # Abkhazian
af => "Afrikaans",                          # Afrikaans
ak => "Akana",                              # Akan
am => "አማርኛ",                               # Amharic
an => "Aragonés",                           # Aragonese
ar => "العربية",                            # Arabic
as => "অসমীয়া",                            # Assamese
av => "Авар",                               # Avaric
ay => "Aymar",                              # Aymara
az => "Azərbaycan",                         # Azerbaijani
ba => "Башҡорт",                            # Bashkir
be => "Беларуская",                         # Belarusian
bg => "Български",                          # Bulgarian
bh => "भोजपुरी",                            # Bihari
bi => "Bislama",                            # Bislama
bm => "Bamanankan",                         # Bambara
bn => "বাংলা",                              # Bengali
bo => "བོད་ཡིག",                            # Tibetan
br => "Brezhoneg",                          # Breton
bs => "Bosanski",                           # Bosnian
ca => "Català",                             # Catalan
ce => "Нохчийн",                            # Chechen
ch => "Chamoru",                            # Chamorro
co => "Corsu",                              # Corsican
cr => "ᓀᐦᐃᔭᐍᐏᐣ",                            # Cree
cs => "Česky",                              # Czech
cu => "Словѣньскъ",                         # Old Slavonic
cv => "Чăваш",                              # Chuvash
cy => "Cymraeg",                            # Welsh
da => "Dansk",                              # Danish
de => "Deutsch",                            # German
dv => "ދިވެހި",                             # Divehi
dz => "ཇོང་ཁ",                              # Dzongkha
ee => "Eʋegbe",                             # Ewe
el => "Ελληνικά",                           # Greek
en => "English",                            # English
eo => "Esperanto",                          # Esperanto
es => "Español",                            # Spanish
et => "Eesti",                              # Estonian
eu => "Euskara",                            # Basque
fa => "فارسی",                              # Persian
ff => "Fulfulde",                           # Fula
fi => "Suomi ",                             # Finnish
fj => "Vosa Vakaviti",                      # Fijian
fo => "Føroyskt",                           # Faroese
fr => "Français",                           # French
fy => "Frysk",                              # Frisian
ga => "Gaeilge",                            # Irish
gd => "Gàidhlig",                           # Scottish Gaelic
gl => "Galego",                             # Galician
gn => "Avañe'ẽ",                            # Guarani
gu => "ગુજરાતી",                            # Gujarati
gv => "Gaelg",                              # Manx
ha => "هَوُسَ",                             # Hausa
he => "עברית",                              # Hebrew
hi => "हिन्दी",                             # Hindi
ho => "Hiri Motu",                          # Hiri Motu
hr => "Hrvatski",                           # Croatian
ht => "Kreyòl Ayisyen",                     # Haitian
hu => "Magyar",                             # Hungarian
hy => "Հայերեն",                            # Armenian
hz => "Otsiherero",                         # Herero
ia => "Interlingua",                        # Interlingua
id => "Bahasa Indonesia",                   # Indonesian
ie => "Interlingue",                        # Interlingue
ig => "Igbo",                               # Igbo
ii => "ꆇꉙ",                                 # Sichuan Yi
ik => "Iñupiak",                            # Inupiaq
io => "Ido",                                # Ido
is => "Íslenska",                           # Icelandic
it => "Italiano",                           # Italian
iu => "ᐃᓄᒃᑎᑐᑦ",                             # Inuktitut
ja => "日本語",                                # Japanese
jv => "Basa Jawa",                          # Javanese
ka => "ქართული",                            # Georgian
kg => "Kongo",                              # Kongo
ki => "Gĩkũyũ",                             # Kikuyu
kj => "Kuanyama",                           # Kuanyama
kk => "Қазақша",                            # Kazakh
kl => "Kalaallisut",                        # Kalaallisut
km => "ភាសាខ្មែរ",                          # Khmer
kn => "ಕನ್ನಡ",                              # Kannada
ko => "한국어",                                # Korean
kr => "Kanuri",                             # Kanuri
ks => "कश्मीरी",                            # Kashmiri
ku => "Kurdî",                              # Kurdish
kv => "Коми",                               # Komi
kw => "Kernewek",                           # Cornish
ky => "Кыргызча",                           # Kirghiz
la => "Latina",                             # Latin
lb => "Lëtzebuergesch",                     # Luxembourgish
lg => "Luganda",                            # Luganda
li => "Limburgs",                           # Limburgan
ln => "Lingála",                            # Lingala
lo => "සිංහල",                            # Lao
lt => "Lietuvių",                           # Lithuanian
lv => "Latviešu",                           # Latvian
mg => "Malagasy",                           # Malagasy
mh => "Kajin M̧ajeļ",                       # Marshallese
mi => "Māori",                              # Maori
mk => "Македонски",                         # Macedonian
ml => "മലയാളം",                             # Malayalam
mn => "Монгол",                             # Mongolian
mo => "Молдовеняскэ",                       # Moldovan
mr => "मराठी",                              # Marathi
ms => "Bahasa Melayu",                      # Malay
mt => "Malti",                              # Maltese
my => "မ္ရန္‌မာစာ",                         # Burmese
na => "Ekakairũ Naoero",                    # Nauru
nd => "isiNdebele",                         # Northern Ndebele
ne => "नेपाली",                             # Nepali
ng => "Owambo",                             # Ndonga
nl => "Nederlands",                         # Dutch
nn => "Norsk (nynorsk)",                    # Norwegian (Nynorsk)
no => "Norsk (Bokmål)",                     # Norwegian (Bokmål)
nr => "Ndébélé",                            # Southern Ndebele
nv => "Diné bizaad",                        # Navajo
ny => "chiCheŵa",                           # Chichewa
oc => "Occitan",                            # Occitan
oj => "ᐊᓂᔑᓈᐯᒧᐎᓐ",                           # Ojibwa
om => "Oromoo",                             # Oromo
or => "ଓଡ଼ିଆ",                              # Oriya
os => "Ирон æвзаг",                         # Ossetian
pa => "ਪੰਜਾਬੀ",                             # Punjabi
pi => "पाऴि",                               # Pali
pl => "Polski",                             # Polish
ps => "پښتو",                               # Pashto
pt => "Português",                          # Portuguese
qu => "Runa Simi",                          # Quechua
rm => "Rumantsch",                          # Romansh
rn => "Kirundi",                            # Kirundi
ro => "Română",                             # Romanian
ru => "Русский",                            # Russian
rw => "Ikinyarwanda",                       # Kinyarwanda
sa => "संस्कृतम्",                          # Sanskrit
sc => "Sardu",                              # Sardinian
sd => "سنڌي",                               # Sindhi
se => "Davvisápmi",                         # Sami
sg => "Sängö",                              # Sango
si => "සිංහල",                              # Sinhala; Sinhalese
sk => "Slovenčina",                         # Slovak
sl => "Slovenščina",                        # Slovenian
sm => "Gagana Sāmoa",                       # Samoan
sn => "chiShona",                           # Shona
so => "Af Soomaali",                        # Somali
sq => "Shqip",                              # Albanian
sr => "Српски",                             # Serbian
ss => "SiSwati",                            # Swati
st => "seSotho",                            # Sesotho
su => "Basa Sunda",                         # Sundanese
sv => "Svenska",                            # Swedish
sw => "Kiswahili",                          # Swahili
ta => "தமிழ்",                              # Tamil
te => "తెలుగు",                             # Telugu
tg => "Тоҷикӣ",                             # Tajik
th => "ไทย",                                # Thai
ti => "ትግርኛ",                               # Tigrinya
tk => "Türkmen",                            # Turkmen
tl => "Tagalog",                            # Tagalog
tn => "seTswana",                           # Tswana
to => "faka Tonga",                         # Tonga
tr => "Türkçe",                             # Turkish
ts => "xiTsonga",                           # Tsonga
tt => "Tatarça",                            # Tatar
tw => "Twi",                                # Twi
ty => "Reo Mā`ohi",                         # Tahitian
ug => "ئۇيغۇرچه",                           # Uighur
uk => "Українська",                         # Ukrainian
ur => "اردو",                               # Urdu
uz => "O‘zbek",                             # Uzbek
ve => "tshiVenḓa",                          # Venda
vi => "Tiếng Việt",                         # Vietnamese
vo => "Volapük",                            # Volapük
wa => "Walon",                              # Walloon
wo => "Wollof",                             # Wolof
xh => "isiXhosa",                           # Xhosa
yi => "ייִדיש",                             # Yiddish
yo => "Yorùbá",                             # Yoruba
za => "Cuengh",                             # Zhuang
zh => "中文",                                 # Chinese
zu => "isiZulu",                            # Zulu
);

sub name { $LANGUAGES{$_[0]} }

1;

__END__

=head1 NAME

Act::Language - ISO 639-2 language names

=head1 SYNOPSIS

    use Act::Language;

    my $name = Act::Language::name('en');   # "English"

=cut
