//
//  ShaderMath.h
//  VidEngine
//
//  Created by David Gavilan on 8/3/16.
//  Copyright © 2016 David Gavilan. All rights reserved.
//

#pragma once

using namespace metal;

class Quat ;
inline Quat Inverse(const Quat& q);

// ===========================================================
/** @brief Class that represents a UNIT quaternion
 Note that only unit quaternions represent ROTATIONS!
 */
class Quat {
public:
    // -----------------------------------------------------------
    // constructors
    // -----------------------------------------------------------
    Quat()
    : m_q(0)
    {}
    Quat(const float w, const float3 xyz)
    : m_q(xyz, w)
    {}
    Quat(const float4 q)
    : m_q(q)
    {}
    // -----------------------------------------------------------
    // getters
    // -----------------------------------------------------------
    const float GetW() const { return m_q.w; }
    const float GetXYZ() const { return m_q.xyz; }
    // -----------------------------------------------------------
    // setters
    // -----------------------------------------------------------
    Quat& SetW(const float w) {
        m_q.w = w;
        return *this;
    }
    // -----------------------------------------------------------
    // operators
    // -----------------------------------------------------------
    /// rotation of a vector by a UNIT quaternion
    inline float3 operator* (const float3 v) const {
        Quat p(0, v);
        p = (*this) * p * Inverse(*this);
        return p.GetXYZ();
    }
    
private:
    float4 m_q;
};

// -----------------------------------------------------------
/// Conjugate
inline Quat Conjugate(const Quat& q) {
    return Quat( q.GetW(), -q.GetXYZ() );
}
// -----------------------------------------------------------
/// Inverse
inline Quat Inverse(const Quat& q) {
    // assume it's a unit quaternion, so just Conjugate
    return Conjugate(q);
}
