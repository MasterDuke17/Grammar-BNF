#!/usr/bin/env perl6

use v6;
use lib './lib';

use Test;

plan 27;

use Grammar::ABNF;

ok 1, 'We use Grammar::ABNF and we are still alive';

lives-ok { grammar G is Grammar::ABNF { token CRLF { "\n" } } },
    'We subclassed Grammar::ABNF';

my @simpletests = (

# Just some preliminary tests for now.  Grammars as keys and things they
# should successfully parse as values.

'foo = %x20
' => ' ',

'foo = %x20.20
' => '  ',

'foo = 4%x61-63
' => 'abca',

'foo = bar
bar = 1*%x61-63
' => 'abca',

'foo = bar phnord
phnord = "abc"
bar = "cde"
' => 'cdeabc'

);

for @simpletests[]:kv -> $c, $p (:key($g), :value($i)) {
    my $a = G.generate($g, :name("SimpleTestABNF$c"));
    is $a.WHAT.gist, "(SimpleTestABNF$c)", "Parse simple test #$c grammar";
    ok $a.parse($i), "Simple test grammar #$c parses material";
}

# Tests for corner cases and spec glitches

# Technically legal?  We allow it.  Section 2.1 says this is "typically
# restricted" to use within prose but does not give an example where it is
# needed inside an actual ABNF rule, and the ABNF-of-ABNF provided will not
# parse this.  But the "typically" weasel word forces us to allow it.
# Also ABNF-of-ABNF does not allow it within <prose-val> so... WTH dudes.
ok G.generate('foo = <bar>
bar = 1*%x61-63
').parse('abca'), "Optional angle brackets around rule names accepted.";

# Test using some grammars from RFCS.
my $rfc4466 = q:to<EOG>;
ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z
BIT            =  "0" / "1"
CHAR           =  %x01-7F
CR             =  %x0D
CRLF           =  lf
CTL            =  %x00-1F / %x7F
DIGIT          =  %x30-39
DQUOTE         =  %x22
HEXDIG         =  digit / "A" / "B" / "C" / "D" / "E" / "F"
HTAB           =  %x09
LF             =  %x0A
LWSP           =  *(wsp / crlf wsp)
OCTET          =  %x00-FF
SP             =  %x20
VCHAR          =  %x21-7E
WSP            =  sp / htab
append          = "APPEND" SP mailbox 1*append-message
append-message  = append-opts SP append-data
append-ext      = append-ext-name SP append-ext-value
append-ext-name = tagged-ext-label
append-ext-value= tagged-ext-val
append-data     = literal / literal8 / append-data-ext
append-data-ext = tagged-ext
append-opts     = [SP flag-list] [SP date-time] *(SP append-ext)
charset         = atom / quoted
create          = "CREATE" SP mailbox [create-params]
create-params   = SP "(" create-param *( SP create-param) ")"
create-param-name = tagged-ext-label
create-param      = create-param-name [SP create-param-value]
create-param-value= tagged-ext-val
esearch-response  = "ESEARCH" [search-correlator] [SP "UID"] *(SP search-return-data)
examine         = "EXAMINE" SP mailbox [select-params]
fetch           = "FETCH" SP sequence-set SP ("ALL" / "FULL" / "FAST" / fetch-att / "(" fetch-att *(SP fetch-att) ")") [fetch-modifiers]
fetch-modifiers = SP "(" fetch-modifier *(SP fetch-modifier) ")"
fetch-modifier  = fetch-modifier-name [ SP fetch-modif-params ]
fetch-modif-params  = tagged-ext-val
fetch-modifier-name = tagged-ext-label
literal8        = "~{" number ["+"] "}" CRLF *OCTET
Namespace         = nil / "(" 1*Namespace-Descr ")"
Namespace-Command = "NAMESPACE"
Namespace-Descr   = "(" string SP (DQUOTE QUOTED-CHAR DQUOTE / nil) *(Namespace-Response-Extension) ")"
Namespace-Response-Extension = SP string SP "(" string *(SP string) ")"
Namespace-Response = "NAMESPACE" SP Namespace SP Namespace SP Namespace
rename          = "RENAME" SP mailbox SP mailbox [rename-params]
rename-params     = SP "(" rename-param *( SP rename-param) ")"
rename-param      = rename-param-name [SP rename-param-value]
rename-param-name = tagged-ext-label
rename-param-value= tagged-ext-val
response-data   = "*" SP response-payload CRLF
response-payload= resp-cond-state / resp-cond-bye / mailbox-data / message-data / capability-data
search          = "SEARCH" [search-return-opts] SP search-program
search-correlator  = SP "(" "TAG" SP tag-string ")"
search-program     = ["CHARSET" SP charset SP] search-key *(SP search-key)
search-return-data = search-modifier-name SP search-return-value
search-return-opts = SP "RETURN" SP "(" [search-return-opt *(SP search-return-opt)] ")"
search-return-opt = search-modifier-name [SP search-mod-params]
search-return-value = tagged-ext-val
search-modifier-name = tagged-ext-label
search-mod-params = tagged-ext-val
select          = "SELECT" SP mailbox [select-params]
select-params   = SP "(" select-param *(SP select-param) ")"
select-param    = select-param-name [SP select-param-value]
select-param-name= tagged-ext-label
select-param-value= tagged-ext-val
status-att-list = status-att-val *(SP status-att-val)
status-att-val  = ("MESSAGES" SP number) / ("RECENT" SP number) / ("UIDNEXT" SP nz-number) / ("UIDVALIDITY" SP nz-number) / ("UNSEEN" SP number)
store           = "STORE" SP sequence-set [store-modifiers] SP store-att-flags
store-modifiers =  SP "(" store-modifier *(SP store-modifier) ")"
store-modifier  = store-modifier-name [SP store-modif-params]
store-modif-params = tagged-ext-val
store-modifier-name = tagged-ext-label
tag-string         = string
tagged-ext          = tagged-ext-label SP tagged-ext-val
tagged-ext-label    = tagged-label-fchar *tagged-label-char
tagged-label-fchar  = ALPHA / "-" / "_" / "."
tagged-label-char   = tagged-label-fchar / DIGIT / ":"
tagged-ext-comp     = astring / tagged-ext-comp *(SP tagged-ext-comp) / "(" tagged-ext-comp ")"
tagged-ext-simple   = sequence-set / number
tagged-ext-val      = tagged-ext-simple / "(" [tagged-ext-comp] ")"
address         = "(" addr-name SP addr-adl SP addr-mailbox SP addr-host ")"
addr-adl        = nstring
addr-host       = nstring
addr-mailbox    = nstring
addr-name       = nstring
astring         = 1*ASTRING-CHAR / string
ASTRING-CHAR   = ATOM-CHAR / resp-specials
atom            = 1*ATOM-CHAR
ATOM-CHAR       = <any CHAR except atom-specials>
atom-specials   = "(" / ")" / "{" / SP / CTL / list-wildcards / quoted-specials / resp-specials
authenticate    = "AUTHENTICATE" SP auth-type *(CRLF base64)
auth-type       = atom
base64          = *(4base64-char) [base64-terminal]
base64-char     = ALPHA / DIGIT / "+" / "/"
base64-terminal = (2base64-char "==") / (3base64-char "=")
body            = "(" (body-type-1part / body-type-mpart) ")"
body-extension  = nstring / number / "(" body-extension *(SP body-extension) ")"
body-ext-1part  = body-fld-md5 [SP body-fld-dsp [SP body-fld-lang [SP body-fld-loc *(SP body-extension)]]]
body-ext-mpart  = body-fld-param [SP body-fld-dsp [SP body-fld-lang [SP body-fld-loc *(SP body-extension)]]]
body-fields     = body-fld-param SP body-fld-id SP body-fld-desc SP body-fld-enc SP body-fld-octets
body-fld-desc   = nstring
body-fld-dsp    = "(" string SP body-fld-param ")" / nil
body-fld-enc    = (DQUOTE ("7BIT" / "8BIT" / "BINARY" / "BASE64"/ "QUOTED-PRINTABLE") DQUOTE) / string
body-fld-id     = nstring
body-fld-lang   = nstring / "(" string *(SP string) ")"
body-fld-loc    = nstring
body-fld-lines  = number
body-fld-md5    = nstring
body-fld-octets = number
body-fld-param  = "(" string SP string *(SP string SP string) ")" / nil
body-type-1part = (body-type-basic / body-type-msg / body-type-text) [SP body-ext-1part]
body-type-basic = media-basic SP body-fields
body-type-mpart = 1*body SP media-subtype [SP body-ext-mpart]
body-type-msg   = media-message SP body-fields SP envelope SP body SP body-fld-lines
body-type-text  = media-text SP body-fields SP body-fld-lines
capability      = ("AUTH=" auth-type) / atom
capability-data = "CAPABILITY" *(SP capability) SP "IMAP4rev1" *(SP capability)
CHAR8           = %x01-ff
command         = tag SP (command-any / command-auth / command-nonauth / command-select) CRLF
command-any     = "CAPABILITY" / "LOGOUT" / "NOOP" / x-command
command-auth    = append / create / delete / examine / list / lsub / rename / select / status / subscribe / unsubscribe
command-nonauth = login / authenticate / "STARTTLS"
command-select  = "CHECK" / "CLOSE" / "EXPUNGE" / copy / fetch / store / uid / search
continue-req    = "+" SP (resp-text / base64) CRLF
copy            = "COPY" SP sequence-set SP mailbox
create          = "CREATE" SP mailbox
date            = date-text / DQUOTE date-text DQUOTE
date-day        = 1*2DIGIT
date-day-fixed  = (SP DIGIT) / 2DIGIT
date-month      = "Jan" / "Feb" / "Mar" / "Apr" / "May" / "Jun" / "Jul" / "Aug" / "Sep" / "Oct" / "Nov" / "Dec"
date-text       = date-day "-" date-month "-" date-year
date-year       = 4DIGIT
date-time       = DQUOTE date-day-fixed "-" date-month "-" date-year SP time SP zone DQUOTE
delete          = "DELETE" SP mailbox
digit-nz        = %x31-39
envelope        = "(" env-date SP env-subject SP env-from SP env-sender SP env-reply-to SP env-to SP env-cc SP env-bcc SP env-in-reply-to SP env-message-id ")"
env-bcc         = "(" 1*address ")" / nil
env-cc          = "(" 1*address ")" / nil
env-date        = nstring
env-from        = "(" 1*address ")" / nil
env-in-reply-to = nstring
env-message-id  = nstring
env-reply-to    = "(" 1*address ")" / nil
env-sender      = "(" 1*address ")" / nil
env-subject     = nstring
env-to          = "(" 1*address ")" / nil
examine         = "EXAMINE" SP mailbox
fetch           = "FETCH" SP sequence-set SP ("ALL" / "FULL" / "FAST" / fetch-att / "(" fetch-att *(SP fetch-att) ")")
fetch-att       = "ENVELOPE" / "FLAGS" / "INTERNALDATE" / "RFC822" [".HEADER" / ".SIZE" / ".TEXT"] / "BODY" ["STRUCTURE"] / "UID" / "BODY" section ["<" number "." nz-number ">"] / "BODY.PEEK" section ["<" number "." nz-number ">"]
flag            = "\Answered" / "\Flagged" / "\Deleted" / "\Seen" / "\Draft" / flag-keyword / flag-extension
flag-extension  = "\" atom
flag-fetch      = flag / "\Recent"
flag-keyword    = atom
flag-list       = "(" [flag *(SP flag)] ")"
flag-perm       = flag / "\*"
greeting        = "*" SP (resp-cond-auth / resp-cond-bye) CRLF
header-fld-name = astring
header-list     = "(" header-fld-name *(SP header-fld-name) ")"
list            = "LIST" SP mailbox SP list-mailbox
list-mailbox    = 1*list-char / string
list-char       = ATOM-CHAR / list-wildcards / resp-specials
list-wildcards  = "%" / "*"
literal         = "{" number "}" CRLF *CHAR8
login           = "LOGIN" SP userid SP password
lsub            = "LSUB" SP mailbox SP list-mailbox
mailbox         = "INBOX" / astring
mailbox-data    =  "FLAGS" SP flag-list / "LIST" SP mailbox-list / "LSUB" SP mailbox-list / "SEARCH" *(SP nz-number) / "STATUS" SP mailbox SP "(" [status-att-list] ")" / number SP "EXISTS" / number SP "RECENT"
mailbox-list    = "(" [mbx-list-flags] ")" SP (DQUOTE QUOTED-CHAR DQUOTE / nil) SP mailbox
mbx-list-flags  = *(mbx-list-oflag SP) mbx-list-sflag *(SP mbx-list-oflag) / mbx-list-oflag *(SP mbx-list-oflag)
mbx-list-oflag  = "\Noinferiors" / flag-extension
mbx-list-sflag  = "\Noselect" / "\Marked" / "\Unmarked"
media-basic     = ((DQUOTE ("APPLICATION" / "AUDIO" / "IMAGE" / "MESSAGE" / "VIDEO") DQUOTE) / string) SP media-subtype
media-message   = DQUOTE "MESSAGE" DQUOTE SP DQUOTE "RFC822" DQUOTE
media-subtype   = string
media-text      = DQUOTE "TEXT" DQUOTE SP media-subtype
message-data    = nz-number SP ("EXPUNGE" / ("FETCH" SP msg-att))
msg-att         = "(" (msg-att-dynamic / msg-att-static) *(SP (msg-att-dynamic / msg-att-static)) ")"
msg-att-dynamic = "FLAGS" SP "(" [flag-fetch *(SP flag-fetch)] ")"
msg-att-static  = "ENVELOPE" SP envelope / "INTERNALDATE" SP date-time / "RFC822" [".HEADER" / ".TEXT"] SP nstring / "RFC822.SIZE" SP number / "BODY" ["STRUCTURE"] SP body / "BODY" section ["<" number ">"] SP nstring / "UID" SP uniqueid
nil             = "NIL"
nstring         = string / nil
number          = 1*DIGIT
nz-number       = digit-nz *DIGIT
password        = astring
quoted          = DQUOTE *QUOTED-CHAR DQUOTE
QUOTED-CHAR     = <any TEXT-CHAR except quoted-specials> / "\" quoted-specials
quoted-specials = DQUOTE / "\"
rename          = "RENAME" SP mailbox SP mailbox
response        = *(continue-req / response-data) response-done
response-data   = "*" SP (resp-cond-state / resp-cond-bye / mailbox-data / message-data / capability-data) CRLF
response-done   = response-tagged / response-fatal
response-fatal  = "*" SP resp-cond-bye CRLF
response-tagged = tag SP resp-cond-state CRLF
resp-cond-auth  = ("OK" / "PREAUTH") SP resp-text
resp-cond-bye   = "BYE" SP resp-text
resp-cond-state = ("OK" / "NO" / "BAD") SP resp-text
resp-specials   = "]"
resp-text       = ["[" resp-text-code "]" SP] text
resp-text-code  = "ALERT" / "BADCHARSET" [SP "(" astring *(SP astring) ")" ] / capability-data / "PARSE" / "PERMANENTFLAGS" SP "(" [flag-perm *(SP flag-perm)] ")" / "READ-ONLY" / "READ-WRITE" / "TRYCREATE" / "UIDNEXT" SP nz-number / "UIDVALIDITY" SP nz-number / "UNSEEN" SP nz-number / atom [SP 1*<any TEXT-CHAR except "]">]
search          = "SEARCH" [SP "CHARSET" SP astring] 1*(SP search-key)
search-key      = "ALL" / "ANSWERED" / "BCC" SP astring / "BEFORE" SP date / "BODY" SP astring / "CC" SP astring / "DELETED" / "FLAGGED" / "FROM" SP astring / "KEYWORD" SP flag-keyword / "NEW" / "OLD" / "ON" SP date / "RECENT" / "SEEN" / "SINCE" SP date / "SUBJECT" SP astring / "TEXT" SP astring / "TO" SP astring / "UNANSWERED" / "UNDELETED" / "UNFLAGGED" / "UNKEYWORD" SP flag-keyword / "UNSEEN" / "DRAFT" / "HEADER" SP header-fld-name SP astring / "LARGER" SP number / "NOT" SP search-key / "OR" SP search-key SP search-key / "SENTBEFORE" SP date / "SENTON" SP date / "SENTSINCE" SP date / "SMALLER" SP number / "UID" SP sequence-set / "UNDRAFT" / sequence-set / "(" search-key *(SP search-key) ")"
section         = "[" [section-spec] "]"
section-msgtext = "HEADER" / "HEADER.FIELDS" [".NOT"] SP header-list / "TEXT"
section-part    = nz-number *("." nz-number)
section-spec    = section-msgtext / (section-part ["." section-text])
section-text    = section-msgtext / "MIME"
select          = "SELECT" SP mailbox
seq-number      = nz-number / "*"
seq-range       = seq-number ":" seq-number
sequence-set    = (seq-number / seq-range) *("," sequence-set)
status          = "STATUS" SP mailbox SP "(" status-att *(SP status-att) ")"
status-att      = "MESSAGES" / "RECENT" / "UIDNEXT" / "UIDVALIDITY" / "UNSEEN"
status-att-list =  status-att SP number *(SP status-att SP number)
store           = "STORE" SP sequence-set SP store-att-flags
store-att-flags = (["+" / "-"] "FLAGS" [".SILENT"]) SP (flag-list / (flag *(SP flag)))
string          = quoted / literal
subscribe       = "SUBSCRIBE" SP mailbox
tag             = 1*<any ASTRING-CHAR except "+">
text            = 1*TEXT-CHAR
TEXT-CHAR       = <any CHAR except CR and LF>
time            = 2DIGIT ":" 2DIGIT ":" 2DIGIT
uid             = "UID" SP (copy / fetch / search / store)
uniqueid        = nz-number
unsubscribe     = "UNSUBSCRIBE" SP mailbox
userid          = astring
x-command       = "X" atom <experimental command arguments>
zone            = ("+" / "-") 4DIGIT
ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z
BIT            =  "0" / "1"
CHAR           =  %x01-7F
CR             =  %x0D
CRLF           =  lf
CTL            =  %x00-1F / %x7F
DIGIT          =  %x30-39
DQUOTE         =  %x22
HEXDIG         =  digit / "A" / "B" / "C" / "D" / "E" / "F"
HTAB           =  %x09
LF             =  %x0A
LWSP           =  *(wsp / crlf wsp)
OCTET          =  %x00-FF
SP             =  %x20
VCHAR          =  %x21-7E
WSP            =  sp / htab
EOG

my $rfc4466g = G.generate($rfc4466, :name("RFC4466"));
is $rfc4466g.WHAT.gist, "(RFC4466)", 'ABNF can parse rfc4466 definitions.';
my $rfc4466g_meths = Set($rfc4466g.^methods.map(*.name));
my $rfc4466g_meths2 = Set($rfc4466.comb(/<after [ ^ | \n ]><-[\s\=]>+/)».lc);
# We had to slightly mangle a couple method names, don't count those.
$rfc4466g_meths2 = Set($rfc4466g_meths2.keys.grep({not $_ ~~ /\-\d/}));
ok $rfc4466g_meths2 ⊆ $rfc4466g_meths, 'rfc4466 class has expected methods';

ok $rfc4466g.parse('EXAMINE INBOX', :rule<examine>),
 'Can parse an rfc4466 examine command';
ok $rfc4466g.parse('FETCH 1 BODY[]', :rule<fetch>),
 'Can parse an rfc4466 fetch command';
throws-like { $rfc4466g.parse('LOGIN MyUsername MyPassword', :rule<login>) },
  X::NYI, message => /
    "This ABNF Grammar requires you to mix in custom code" .+?
    "any CHAR except atom-specials" .+?
    "which you may have to write yourself"
  /;

throws-like { $rfc4466g.parse("foo", :rule<fake-rule-name>) }, X::Method::NotFound;

# Complex tests.

my $abnf_of_abnf = q:to<EOG>;
rulelist       =  1*( rule / (*c-wsp c-nl) )
rule           =  rulename defined-as elements c-nl
rulename       =  alpha *(alpha / digit / "-")
defined-as     =  *c-wsp ("=" / "=/") *c-wsp
elements       =  alternation *c-wsp
c-wsp          =  wsp / (c-nl wsp)
c-nl           =  comment / crlf
comment        =  ";" *(wsp / vchar) crlf
alternation    =  concatenation *(*c-wsp "/" *c-wsp concatenation)
concatenation  =  repetition *(1*c-wsp repetition)
repetition     =  [repeat] element
repeat         =  1*digit / (*digit "*" *digit)
element        =  rulename / group / option / char-val / num-val / prose-val
group          =  "(" *c-wsp alternation *c-wsp ")"
option         =  "[" *c-wsp alternation *c-wsp "]"
char-val       =  dquote *(%x20-21 / %x23-7E) dquote
num-val        =  "%" (bin-val / dec-val / hex-val)
bin-val        =  "b" 1*bit [ 1*("." 1*bit) / ("-" 1*bit) ]
dec-val        =  "d" 1*digit [ 1*("." 1*digit) / ("-" 1*digit) ]
hex-val        =  "x" 1*hexdig [ 1*("." 1*hexdig) / ("-" 1*hexdig) ]
prose-val      =  "<" *(%x20-3D / %x3F-7E) ">"
ALPHA          =  %x41-5A / %x61-7A   ; A-Z / a-z
BIT            =  "0" / "1"
CHAR           =  %x01-7F
CR             =  %x0D
CRLF           =  lf
CTL            =  %x00-1F / %x7F
DIGIT          =  %x30-39
DQUOTE         =  %x22
HEXDIG         =  digit / "A" / "B" / "C" / "D" / "E" / "F"
HTAB           =  %x09
LF             =  %x0A
LWSP           =  *(wsp / crlf wsp)
OCTET          =  %x00-FF
SP             =  %x20
VCHAR          =  %x21-7E
WSP            =  sp / htab
EOG

my $abnf2 = G.generate($abnf_of_abnf, :name("ABNF_of_ABNF"));
is $abnf2.WHAT.gist, "(ABNF_of_ABNF)", 'ABNF can parse its own definition.';

for @simpletests[]:kv -> $c, $p (:key($g), :value($i)) {

    # ABNF itself does not have <.rulename>, and the default implementation
    # in perl6 elides trivial rules.  Also, we have a couple extra visible
    # rules in the perl6 implementation, and they do not always produce
    # <repeat> in the same way.
    #
    # So we fix those up before we score the test.
    my $derived_gist = $abnf2.parse($g).gist.lines.grep(
        { $_ !~~ /[ ^\s*
          [ alpha | hexdig | digit | c\-wsp | repeat
          | dquote | wsp | sp | c\-nl | crlf | lf ]
          \s+ \=\> ] | [ ^\s*\｣ ]/ }).join;
    my $direct_gist = G.parse($g, :name("DeepTest$c")).gist.lines.grep(
        { $_ !~~ /[ ^\s*
          [ repeat | name | 0 | val | min | star | max ]
          \s+ \=\> ] | [ ^\s*\｣ ]/ }).join;

    is $derived_gist, $direct_gist,
        "Derived grammar ($c) produces same results";
}

use Slang::ABNF;

abnf-grammar A::C {
foo = "bar"
};

ok(A::C.parse("bar"), "Parse succeeds");
ok(!A::C.parse("far"), "Parse fails when it doesn't match");
