#pragma once

#include <functional>
#include <algorithm>

#define unless(x) if(!(x))
#define elif(x) else if(x)
#define repeat(x) for(auto i=0; i < x; ++i)
#define until(x) while(!(x))

template<class _coll, class _Fn1> inline
_Fn1 foreach(_coll x, _Fn1 _Func)
    return std::for_each(x.begin(), x.end(), _Func)
