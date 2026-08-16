Pod::Spec.new do |s|
  s.name = "MapConductorHeatmap"
  s.version = "1.3.1"
  s.summary = "MapConductor's tile-based heatmap overlay extension."
  s.license = { :type => "Apache-2.0", :file => "LICENSE" }
  s.author = "MapConductor"
  s.homepage = "https://github.com/MapConductor/ios-heatmap"
  s.source = { :git => "https://github.com/MapConductor/ios-heatmap.git", :tag => s.version.to_s }
  s.platform = :ios, "15.1"
  s.swift_version = "5.9"
  s.source_files = "Sources/MapConductorHeatmap/**/*.swift"
  s.dependency "MapConductorCore"
end
