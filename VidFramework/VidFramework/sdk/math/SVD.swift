//
//  SVD.swift
//  VidFramework
//
//  Created by David Gavilan on 2019/03/23.
//  Copyright © 2019 David Gavilan. All rights reserved.
//

import Accelerate
import simd

// https://gist.github.com/wannyk/04c1f48161780322c0bb
/// array is a column-wise matrix m * n
func svd(array x:[Double], m:Int, n:Int) -> (u:[Double], s:[Double], v:[Double]) {
    var JOBZ = Int8(UnicodeScalar("A").value)
    var M = __CLPK_integer(m)
    var N = __CLPK_integer(n)
    var A = x
    var LDA = __CLPK_integer(m)
    var S = [__CLPK_doublereal](repeating: 0.0, count: min(m,n))
    var U = [__CLPK_doublereal](repeating: 0.0, count: m*m)
    var LDU = __CLPK_integer(m)
    var VT = [__CLPK_doublereal](repeating: 0.0, count: n*n)
    var LDVT = __CLPK_integer(n)
    let lwork = min(m,n)*(6+4*min(m,n))+max(m,n)
    var WORK = [__CLPK_doublereal](repeating: 0.0, count: lwork)
    var LWORK = __CLPK_integer(lwork)
    var IWORK = [__CLPK_integer](repeating: 0, count: 8*min(m,n))
    var INFO = __CLPK_integer(0)
    dgesdd_(&JOBZ, &M, &N, &A, &LDA, &S, &U, &LDU, &VT, &LDVT, &WORK, &LWORK, &IWORK, &INFO)
    var s = [Double](repeating: 0.0, count: m*n)
    for ni in 0...n-1 {
        s[ni*m+ni] = S[ni]
    }
    var v = [Double](repeating: 0.0, count: n*n)
    vDSP_mtransD(VT, 1, &v, 1, vDSP_Length(n), vDSP_Length(n))
    return (U, s, v)
}

public func svd(matrix m: float3x3) -> (float3x3, float3, float3x3) {
    let (c0, c1, c2) = m.columns
    let d0 = [Double(c0.x), Double(c0.y), Double(c0.z)]
    let d1 = [Double(c1.x), Double(c1.y), Double(c1.z)]
    let d2 = [Double(c2.x), Double(c2.y), Double(c2.z)]
    let flatArray = d0 + d1 + d2
    let (u, s, v) = svd(array: flatArray, m: 3, n: 3)
    let uf = u.map { Float($0) }
    let sf = s.map { Float($0) }
    let vf = v.map { Float($0) }
    let U = float3x3(
        float3(uf[0], uf[1], uf[2]),
        float3(uf[3], uf[4], uf[5]),
        float3(uf[6], uf[7], uf[8]))
    let S = float3(sf[0], sf[4], sf[8])
    let V = float3x3(
        float3(vf[0], vf[1], vf[2]),
        float3(vf[3], vf[4], vf[5]),
        float3(vf[6], vf[7], vf[8]))
    return (U, S, V)
}
