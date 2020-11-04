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

  depends_on "python@3.8"
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

  resource "importlib-metadata" do
    url "https://files.pythonhosted.org/packages/56/1f/74c3e29389d34feea2d62ba3de1169efea2566eb22e9546d379756860525/importlib_metadata-2.0.0.tar.gz"
    sha256 "77a540690e24b0305878c37ffd421785a6f7e53c8b5720d211b211de8d0e95da"
  end

  patch :DATA

  def install
    # Default to Python 3.8
    python = Formula["python@3.8"].opt_bin/"python3"
    ENV["PYTHON"] = python
    # virtualenv_install_with_resources
    # Create a virtualenv in `libexec`. If your app needs Python 3, make sure that
    # `depends_on "python"` is declared, and use `virtualenv_create(libexec, "python3")`.
    venv = virtualenv_create(libexec, python)
    # Install all of the resources declared on the formula into the virtualenv.
    venv.pip_install resources

    puts "buildpath --> #{buildpath}"
    puts "Dir.pwd --> #{Dir.pwd}"

    # Copy files to prefix
    prefix.install Dir['{.[^\.]*,*}']

    # Run install scripts directly in prefix
    cd "#{prefix}/code" do
        system "./install.sh", "-p", "python3.8"
    end

    bin.install_symlink "#{prefix}/code/bin/zato"
  end
end
__END__

diff --git a/code/_install-mac.sh b/code/_install-mac.sh
index c0b3897c2..896517153 100644
--- a/code/_install-mac.sh
+++ b/code/_install-mac.sh
@@ -1,23 +1,13 @@
 #!/bin/bash

-if ! [[ "$(type -p brew)" ]]
-then
-    echo "install.sh: Mac : please install Homebrew first." >&2
-    exit 1
-fi
-
 # Python version to use needs to be provided by our caller
 PY_BINARY=$1
 echo "*** Zato Mac installation using $PY_BINARY ***"

-brew install \
-    autoconf automake bzip2 curl git gsasl haproxy libev libevent libffi libtool libxml2 libxslt \
-    libyaml openldap openssl ossp-uuid pkg-config postgresql python3 swig \
-    || true
-
 curl https://bootstrap.pypa.io/get-pip.py | $(type -p $PY_BINARY)
 $PY_BINARY -m pip install -U virtualenv --ignore-installed

 $PY_BINARY -m virtualenv .
 source ./bin/activate
+./bin/python -m pip install -U setuptools pip
 source ./_postinstall.sh $PY_BINARY
diff --git a/code/_postinstall.sh b/code/_postinstall.sh
index 7b86d7eb3..1e1e4dfa1 100644
--- a/code/_postinstall.sh
+++ b/code/_postinstall.sh
@@ -1,5 +1,24 @@
 #!/bin/bash

+function switch_to_basedir()
+{
+    local dir="${BASH_SOURCE[0]}"
+
+    if [[ "$(uname -s)" == 'Darwin' ]]
+    then
+        local f="-f"
+    fi
+
+    while ([ -L "${dir}" ])
+    do
+        dir="$(readlink $f "$dir")"
+    done
+
+    basepath="$(dirname "${dir}")"
+}
+
+switch_to_basedir
+
 # Handles non-system aspects of Zato installation. By the time it runs:
 #   * the target virtualenv must be active.
 #   * the CWD must be the zato/code/ directory.
@@ -62,24 +81,25 @@ echo "$VIRTUAL_ENV/zato_extra_paths" >> eggs/easy-install.pth
 ln -fs $VIRTUAL_ENV/zato_extra_paths extlib

 # Apply patches.
-patch -p0 -d eggs < patches/butler/__init__.py.diff
-patch -p0 -d eggs < patches/configobj.py.diff
-patch -p0 -d eggs < patches/django/db/models/base.py.diff
-patch -p0 --binary -d eggs < patches/ntlm/HTTPNtlmAuthHandler.py.diff
-patch -p0 -d eggs < patches/pykafka/topic.py.diff
-patch -p0 -d eggs < patches/redis/redis/connection.py.diff
-patch -p0 -d eggs < patches/requests/models.py.diff
-patch -p0 -d eggs < patches/requests/sessions.py.diff
-patch -p0 -d eggs < patches/ws4py/server/geventserver.py.diff
+
+patch -p0 -d eggs < $basepath/patches/butler/__init__.py.diff
+patch -p0 -d eggs < $basepath/patches/configobj.py.diff
+patch -p0 -d eggs < $basepath/patches/django/db/models/base.py.diff
+patch -p0 --binary -d eggs < $basepath/patches/ntlm/HTTPNtlmAuthHandler.py.diff
+patch -p0 -d eggs < $basepath/patches/pykafka/topic.py.diff
+patch -p0 -d eggs < $basepath/patches/redis/redis/connection.py.diff
+patch -p0 -d eggs < $basepath/patches/requests/models.py.diff
+patch -p0 -d eggs < $basepath/patches/requests/sessions.py.diff
+patch -p0 -d eggs < $basepath/patches/ws4py/server/geventserver.py.diff

 #
 # On SUSE, SQLAlchemy installs to lib64 instead of lib.
 #
 if [ "$(type -p zypper)" ]
 then
-    patch -p0 -d eggs64 < patches/sqlalchemy/sql/crud.py.diff
+    patch -p0 -d eggs64 < $basepath/patches/sqlalchemy/sql/crud.py.diff
 else
-    patch -p0 -d eggs < patches/sqlalchemy/sql/crud.py.diff
+    patch -p0 -d eggs < $basepath/patches/sqlalchemy/sql/crud.py.diff
 fi

 # Add the 'zato' command ..
diff --git a/code/requirements.txt b/code/requirements.txt
index 3dd17aa5e..de4955ce3 100644
--- a/code/requirements.txt
+++ b/code/requirements.txt
@@ -31,7 +31,7 @@ flake8==2.1.0
 fs==2.4.11
 future==0.18.2
 futures==2.1.6
-gevent==20.6.2
+https://github.com/gevent/gevent/archive/20.6.2.zip
 greenify==0.3.2
 greenlet==0.4.16
 hiredis==0.3.1
