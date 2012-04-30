package Data::Sah::Compiler::perl::I18N::id;
use parent qw(Data::Sah::Compiler::perl::I18N);

use Locale::Maketext::Lexicon::Gettext;
our %Lexicon = %{ Locale::Maketext::Lexicon::Gettext->parse(<DATA>) };

# VERSION

#use Data::Dump; dd \%Lexicon;

1;
# ABSTRACT: Indonesian translation
__DATA__
msgid  ""
msgstr ""
