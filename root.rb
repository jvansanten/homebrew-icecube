require 'formula'

class Root < Formula
  homepage 'http://root.cern.ch'
  url 'https://root.cern.ch/download/root_v5.34.11.source.tar.gz'
  version '5.34.11'
  sha1 '1bda865a38f05f6f447671d1904bd1ca52d42932'
  head 'https://github.com/root-mirror/root.git', :branch => 'v5-34-00-patches'

  bottle do
    sha1 '7f6abbf1bf9373764d8564e90552e8a1a03ed52d' => :mountain_lion
    sha1 '6fb8a9c43c8ab9908571677634319c18d15ff8ea' => :lion
    sha1 'a4f560c56436285635e03fdcd693d7e69320bbe9' => :snow_leopard
  end

  depends_on 'xrootd' => :recommended
  depends_on 'fftw' => :optional
  depends_on :x11 => :recommended
  depends_on :python
  depends_on 'pythia6'
  depends_on 'gsl'

  def install
    # brew audit doesn't like non-executables in bin
    # so we will move {thisroot,setxrd}.{c,}sh to libexec
    # (and change any references to them)
    inreplace Dir['config/roots.in', 'config/thisroot.*sh',
                  'etc/proof/utils/pq2/setup-pq2',
                  'man/man1/setup-pq2.1', 'README/INSTALL', 'README/README'],
      /bin.thisroot/, 'libexec/thisroot'

    # Determine architecture
    arch = MacOS.prefer_64_bit? ? 'macosx64' : 'macosx'

    # N.B. that it is absolutely essential to specify
    # the --etcdir flag to the configure script.  This is
    # due to a long-known issue with ROOT where it will
    # not display any graphical components if the directory
    # is not specified:
    # http://root.cern.ch/phpBB3/viewtopic.php?f=3&t=15072
    args = [ "./configure",
           "#{arch}",
           "--all",
           "--enable-builtin-glew",
           "--prefix=#{prefix}",
           "--etcdir=#{prefix}/etc/root",
           "--mandir=#{man}" ] * ' '

    if build.without? 'x11'
      args = [ args, '--disable-x11' ] * ' '
    end

    system args
    system "make"
    system "make install"

    # needed to run test suite
    prefix.install 'test'

    libexec.mkpath
    mv Dir["#{bin}/*.*sh"], libexec
  end

  def test
    system "make -C #{prefix}/test/ hsimple"
    system "#{prefix}/test/hsimple"
  end

  def caveats; <<-EOS.undent
    Because ROOT depends on several installation-dependent
    environment variables to function properly, you should
    add the following commands to your shell initialization
    script (.bashrc/.profile/etc.), or call them directly
    before using ROOT.

    For csh/tcsh users:
      source `brew --prefix root`/libexec/thisroot.csh
    For bash/zsh users:
      . $(brew --prefix root)/libexec/thisroot.sh
    EOS
  end
end
