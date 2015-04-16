class GraphTool < Formula
  homepage "http://graph-tool.skewed.de/"
  url "http://downloads.skewed.de/graph-tool/graph-tool-2.2.40.tar.bz2"
  sha256 "5ccf2f174663c02d0d8548254d29dbc7f652655d13c1902dafc587c9a1c156e7"

  head do
    url "https://github.com/count0/graph-tool.git"
    depends_on "autoconf" => :build
    depends_on "automake" => :build
    depends_on "libtool" => :build
  end

  option "without-cairo", "Build without cairo support for plotting"
  option "without-gtk+3", "Build without gtk+3 support for interactive plotting"

  cxx11 = MacOS.version < :mavericks ? ["c++11"] : []
  with_pythons = build.with?("python3") ? ["with-python3"] : []

  depends_on "pkg-config" => :build
  depends_on "boost" => cxx11
  depends_on "cairomm" => cxx11 if build.with? "cairo"
  depends_on "cgal" => cxx11
  depends_on "google-sparsehash" => cxx11 + [:recommended]
  depends_on "gtk+3" => :recommended
  depends_on :python => :recommended
  depends_on :python3 => :optional
  depends_on "boost-python" => cxx11 + with_pythons

  if build.with? "gtk+3"
    depends_on "gnome-icon-theme"
    depends_on "librsvg" => "with-gtk+3"
    depends_on "pygobject3" => with_pythons
  end

  if build.with? "python"
    depends_on "py2cairo" if build.with? "cairo"
    depends_on "matplotlib" => :python
    depends_on "numpy" => :python
    depends_on "scipy" => :python
  end

  if build.with? "python3"
    depends_on "py3cairo" if build.with? "cairo"
    depends_on "matplotlib" => :python3
    depends_on "numpy" => :python3
    depends_on "scipy" => :python3
  end

  stable do
    # fix import if gtk+3 or cairo isn't present
    # https://github.com/Homebrew/homebrew-science/pull/2108#issuecomment-94138693
    patch do
      url "https://github.com/count0/graph-tool/commit/c8f99e7c.diff"
      sha256 "ecebc6b311ea438506e32a4ea0f74964e661118a562b7bc71563dfb9c3cf4407"
    end
  end

  def install
    ENV.cxx11

    system "./autogen.sh" if build.head?

    config_args = %W[
      --disable-debug
      --disable-dependency-tracking
      --disable-optimization
      --prefix=#{prefix}
    ]

    config_args << "--disable-cairo" if build.without? "cairo"
    config_args << "--disable-sparsehash" if build.without? "google-sparsehash"

    Language::Python.each_python(build) do |python, version|
      config_args_x = ["PYTHON=#{python}"]
      config_args_x << "PYTHON_EXTRA_LDFLAGS=#{`#{python}-config --ldflags`.chomp}"
      config_args_x << "--with-python-module-path=#{lib}/python#{version}/site-packages"

      if python == "python3"
        inreplace "configure", "libboost_python", "libboost_python3"
      end

      mkdir "build-#{python}-#{version}" do
        system "../configure", *(config_args + config_args_x)
        system "make", "install"
      end
    end
  end

  test do
    Pathname("test.py").write <<-EOS.undent
      import graph_tool.all as gt
      g = gt.Graph()
      v1 = g.add_vertex()
      v2 = g.add_vertex()
      e = g.add_edge(v1, v2)
    EOS
    Language::Python.each_python(build) { |python, _| system python, "test.py" }
  end
end
