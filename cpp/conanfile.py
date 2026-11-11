from conan import ConanFile
from conan.tools.build import check_min_cppstd
from conan.tools.cmake import CMake, CMakeDeps, CMakeToolchain, cmake_layout
from conan.tools.files import copy


class Noosh24Conan(ConanFile):
    name = "noosh24"
    version = "0.1.0"
    license = "MIT"
    homepage = "https://developer.noosh24.com"
    url = "https://developer.noosh24.com"
    description = "Official C++ client for the Noosh24 Open API"
    topics = ("noosh24", "open-api", "restaurant", "sdk")
    package_type = "library"
    settings = "os", "compiler", "build_type", "arch"
    options = {"shared": [True, False], "fPIC": [True, False]}
    default_options = {"shared": False, "fPIC": True}
    exports_sources = "CMakeLists.txt", "cmake/*", "include/*", "src/*", "LICENSE"

    def config_options(self):
        if self.settings.os == "Windows":
            del self.options.fPIC

    def configure(self):
        if self.options.shared:
            self.options.rm_safe("fPIC")

    def validate(self):
        check_min_cppstd(self, 20)

    def layout(self):
        cmake_layout(self)

    def requirements(self):
        self.requires("libcurl/[>=8.0 <9]")
        self.requires("nlohmann_json/3.12.0", transitive_headers=True)

    def generate(self):
        CMakeDeps(self).generate()
        toolchain = CMakeToolchain(self)
        toolchain.cache_variables["NOOSH24_BUILD_TESTS"] = False
        toolchain.cache_variables["NOOSH24_WARNINGS_AS_ERRORS"] = False
        toolchain.generate()

    def build(self):
        cmake = CMake(self)
        cmake.configure()
        cmake.build()

    def package(self):
        copy(self, "LICENSE", self.source_folder, self.package_folder + "/licenses")
        CMake(self).install()

    def package_info(self):
        self.cpp_info.libs = ["noosh24"]
        self.cpp_info.set_property("cmake_file_name", "noosh24")
        self.cpp_info.set_property("cmake_target_name", "noosh24::noosh24")
        self.cpp_info.requires = ["libcurl::libcurl", "nlohmann_json::nlohmann_json"]
