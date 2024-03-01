//
//  Spectrum.swift
//  VidFramework
//
//  Created by David Gavilan on 2018/03/15.
//

import simd

public class Spectrum {
    fileprivate let data : [Int : Float]
    fileprivate let sortedKeys : [Int]
    
    public init(data: [Int : Float]) {
        self.data = data
        let keys : [Int] = Array(data.keys)
        sortedKeys = keys.sorted { $0 < $1 }
    }
    
    // linearly interpolate between the closest wavelengths (in nm)
    public func getIntensity(_ wavelength: Int) -> Float {
        // exact match
        if let me = data[wavelength] {
            return me
        }
        // clamp
        if wavelength < sortedKeys.first! {
            return data[sortedKeys.first!]!
        }
        if wavelength > sortedKeys.last! {
            return data[sortedKeys.last!]!
        }
        // interpolate
        let i1 = sortedKeys.binarySearch { wavelength > $0 }
        let i0 = (i1 - 1)
        let w1 = sortedKeys[i1]
        let w0 = sortedKeys[i0]
        let alpha = Float(wavelength - w0) / Float(w1 - w0)
        let m1 = data[w1]!
        let m0 = data[w0]!
        return (1-alpha) * m0 + alpha * m1
    }
}

public extension CieXYZ {
    
    // http://www.fourmilab.ch/documents/specrend/
    init(spectrum: Spectrum) {
        /* CIE colour matching functions xBar, yBar, and zBar for
         wavelengths from 380 through 780 nanometers, every 5
         nanometers.  For a wavelength lambda in this range:
         
         cie_colour_match[(lambda - 380) / 5][0] = xBar
         cie_colour_match[(lambda - 380) / 5][1] = yBar
         cie_colour_match[(lambda - 380) / 5][2] = zBar
         */
        let cieColourMatch : [simd_float3] = [
            simd_float3(0.0014,0.0000,0.0065), simd_float3(0.0022,0.0001,0.0105), simd_float3(0.0042,0.0001,0.0201),
            simd_float3(0.0076,0.0002,0.0362), simd_float3(0.0143,0.0004,0.0679), simd_float3(0.0232,0.0006,0.1102),
            simd_float3(0.0435,0.0012,0.2074), simd_float3(0.0776,0.0022,0.3713), simd_float3(0.1344,0.0040,0.6456),
            simd_float3(0.2148,0.0073,1.0391), simd_float3(0.2839,0.0116,1.3856), simd_float3(0.3285,0.0168,1.6230),
            simd_float3(0.3483,0.0230,1.7471), simd_float3(0.3481,0.0298,1.7826), simd_float3(0.3362,0.0380,1.7721),
            simd_float3(0.3187,0.0480,1.7441), simd_float3(0.2908,0.0600,1.6692), simd_float3(0.2511,0.0739,1.5281),
            simd_float3(0.1954,0.0910,1.2876), simd_float3(0.1421,0.1126,1.0419), simd_float3(0.0956,0.1390,0.8130),
            simd_float3(0.0580,0.1693,0.6162), simd_float3(0.0320,0.2080,0.4652), simd_float3(0.0147,0.2586,0.3533),
            simd_float3(0.0049,0.3230,0.2720), simd_float3(0.0024,0.4073,0.2123), simd_float3(0.0093,0.5030,0.1582),
            simd_float3(0.0291,0.6082,0.1117), simd_float3(0.0633,0.7100,0.0782), simd_float3(0.1096,0.7932,0.0573),
            simd_float3(0.1655,0.8620,0.0422), simd_float3(0.2257,0.9149,0.0298), simd_float3(0.2904,0.9540,0.0203),
            simd_float3(0.3597,0.9803,0.0134), simd_float3(0.4334,0.9950,0.0087), simd_float3(0.5121,1.0000,0.0057),
            simd_float3(0.5945,0.9950,0.0039), simd_float3(0.6784,0.9786,0.0027), simd_float3(0.7621,0.9520,0.0021),
            simd_float3(0.8425,0.9154,0.0018), simd_float3(0.9163,0.8700,0.0017), simd_float3(0.9786,0.8163,0.0014),
            simd_float3(1.0263,0.7570,0.0011), simd_float3(1.0567,0.6949,0.0010), simd_float3(1.0622,0.6310,0.0008),
            simd_float3(1.0456,0.5668,0.0006), simd_float3(1.0026,0.5030,0.0003), simd_float3(0.9384,0.4412,0.0002),
            simd_float3(0.8544,0.3810,0.0002), simd_float3(0.7514,0.3210,0.0001), simd_float3(0.6424,0.2650,0.0000),
            simd_float3(0.5419,0.2170,0.0000), simd_float3(0.4479,0.1750,0.0000), simd_float3(0.3608,0.1382,0.0000),
            simd_float3(0.2835,0.1070,0.0000), simd_float3(0.2187,0.0816,0.0000), simd_float3(0.1649,0.0610,0.0000),
            simd_float3(0.1212,0.0446,0.0000), simd_float3(0.0874,0.0320,0.0000), simd_float3(0.0636,0.0232,0.0000),
            simd_float3(0.0468,0.0170,0.0000), simd_float3(0.0329,0.0119,0.0000), simd_float3(0.0227,0.0082,0.0000),
            simd_float3(0.0158,0.0057,0.0000), simd_float3(0.0114,0.0041,0.0000), simd_float3(0.0081,0.0029,0.0000),
            simd_float3(0.0058,0.0021,0.0000), simd_float3(0.0041,0.0015,0.0000), simd_float3(0.0029,0.0010,0.0000),
            simd_float3(0.0020,0.0007,0.0000), simd_float3(0.0014,0.0005,0.0000), simd_float3(0.0010,0.0004,0.0000),
            simd_float3(0.0007,0.0002,0.0000), simd_float3(0.0005,0.0002,0.0000), simd_float3(0.0003,0.0001,0.0000),
            simd_float3(0.0002,0.0001,0.0000), simd_float3(0.0002,0.0001,0.0000), simd_float3(0.0001,0.0000,0.0000),
            simd_float3(0.0001,0.0000,0.0000), simd_float3(0.0001,0.0000,0.0000), simd_float3(0.0000,0.0000,0.0000)
        ]
        var lambda : Int = 380
        var xyz = simd_float3(0,0,0)
        for i in 0..<cieColourMatch.count {
            let me = spectrum.getIntensity(lambda)
            xyz = xyz + me * cieColourMatch[i]
            lambda += 5
        }
        let sum = xyz.x + xyz.y + xyz.z
        self.xyz = (1 / sum) * xyz
    }
}
