use inc::Module::Install;

name     'Class-LOP';
all_from 'lib/Class/LOP.pm';
author   q{Brad Haywood <brad@perlpowered.com>};
license  'perl';

build_requires 'Test::More';

auto_install;

WriteAll;

