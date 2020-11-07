class Zato < Formula
  include Language::Python::Virtualenv

  desc "The next generation ESB and application server. Open-source. In Python"
  homepage "http://zato.io"
  head "https://github.com/zatosource/zato.git", :branch => "anielkis-f-gh827-osx-support" # , :branch => "main"
                                         #, :revision => "090930930295adslfknsdfsdaffnasd13"
                                         # or :branch => "develop" (the default is "master")
                                         # or :tag => "1_0_release",
                                         #    :revision => "090930930295adslfknsdfsdaffnasd13"

  version "3.2.0"
  # sha256 ""
  # license "LGPLv3"

  depends_on "python@3.9"
  depends_on "pyenv-virtualenvwrapper"
  depends_on "llvm"
  depends_on "autoconf"
  depends_on "automake"
  depends_on "bzip2"
  depends_on "curl"
  depends_on "git"
  depends_on "gsasl"
  depends_on "haproxy"
  depends_on "libev"
  depends_on "libevent"
  depends_on "libffi"
  depends_on "libtool"
  depends_on "libxml2"
  depends_on "libxslt"
  depends_on "libyaml"
  depends_on "openldap"
  depends_on "openssl"
  depends_on "ossp-uuid"
  depends_on "pkg-config"
  depends_on "redis"
  depends_on "swig"
  depends_on "coreutils"

  resource "importlib-metadata" do
    url "https://files.pythonhosted.org/packages/56/1f/74c3e29389d34feea2d62ba3de1169efea2566eb22e9546d379756860525/importlib_metadata-2.0.0.tar.gz"
    sha256 "77a540690e24b0305878c37ffd421785a6f7e53c8b5720d211b211de8d0e95da"
  end

  def install
    # Default to Python 3.9
    python = Formula["python@3.9"].opt_bin/"python3"
    ENV["PYTHON"] = python
    venv = virtualenv_create(libexec, python)
    venv.pip_install resources

    # Copy files to prefix
    prefix.install Dir['{.[^\.]*,*}']

    # Run scripts directly in prefix
    cd "#{prefix}/code" do
        # system_command("./install.sh", args: ["-p", "python3.9"], print_stdout: false)
        Open3.popen3(["./install.sh", "-p", "python3.9"]) do |_, stdout, stderr, wait_thread|
          [stdout.read, stderr.read, wait_thread.value]
        end
        # system "./install.sh", "-p", "python3.9", :print_stdout => true, :verbose => true
    end

    bin.install_symlink "#{prefix}/code/bin/zato"
  end
end
