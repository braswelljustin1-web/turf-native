"""Pure decimal arithmetic. No product identity or application approval is accepted."""
from decimal import Decimal, localcontext, ROUND_HALF_EVEN
import re

VERSION = '1.0.0'
UNITS = {'oz_mass', 'g', 'kg', 'lb', 'us_fl_oz', 'mL', 'L', 'us_gal'}
AREA = {'sq_ft': Decimal(1), 'acre': Decimal(43560), 'sq_m': Decimal(1)/Decimal('0.09290304'), 'ha': Decimal(10000)/Decimal('0.09290304')}

class CalculationError(ValueError):
    pass

def number(value, allow_zero=False):
    if not isinstance(value, str) or not re.fullmatch(r'[0-9]{1,10}(?:\.[0-9]{1,9})?', value):
        raise CalculationError('Use decimal digits and a dot; no grouping, exponent, sign, or ambiguous units.')
    result = Decimal(value)
    if result > Decimal('1000000000') or result < 0 or (result == 0 and not allow_zero):
        raise CalculationError('Value must be positive and at most 1,000,000,000.')
    return result

def calculate(kind, inputs):
    if not isinstance(inputs, dict):
        raise CalculationError('Inputs must be an object.')
    def n(key, zero=False):
        if key not in inputs: raise CalculationError('Missing input: '+key)
        return number(inputs[key], zero)
    with localcontext() as ctx:
        ctx.prec = 38
        ctx.rounding = ROUND_HALF_EVEN
        out = {}
        if kind in ('area_rate', 'tank', 'recipe'):
            if inputs.get('unit') not in UNITS:
                raise CalculationError('Choose an explicit mass or liquid-volume unit; oz is ambiguous.')
            unit = inputs['unit']
        if kind == 'area_rate':
            if inputs.get('area_unit') not in AREA or inputs.get('basis_unit') not in AREA:
                raise CalculationError('Select an explicit area and rate-basis unit.')
            # Apply exact metric conversion inside this precision context.
            def factor(u):
                return {'sq_ft':Decimal(1),'acre':Decimal(43560),'sq_m':Decimal(1)/Decimal('0.09290304'),'ha':Decimal(10000)/Decimal('0.09290304')}[u]
            area = n('area')*factor(inputs['area_unit'])
            basis = n('basis')*factor(inputs['basis_unit'])
            out = {'amount':n('rate',True)*area/basis,'treated_sq_ft':area}
        elif kind == 'tank':
            coverage = n('tank')/n('carrier')*1000
            amount = n('rate',True)*coverage/n('basis_sq_ft')
            out = {'coverage_sq_ft':coverage,'amount':amount,'per_us_gal':amount/n('tank')}
            if unit == 'oz_mass': out['grams'] = amount*Decimal('28.349523125')
        elif kind == 'recipe':
            if inputs.get('volume_basis') != 'final_solution':
                raise CalculationError('Confirm final solution volume, not starting water.')
            concentration = n('product',True)/n('tank')
            out = {'per_us_gal':concentration,'per_1000_sq_ft':concentration*n('carrier'),'per_acre':concentration*n('carrier')*Decimal('43.56')}
        elif kind == 'percent_vv':
            p=n('percent',True)
            if p>100: raise CalculationError('Percent must not exceed 100.')
            out={'us_gal':p/100*n('tank'),'us_fl_oz':p/100*n('tank')*128}
        elif kind == 'fertilizer':
            percent=n('percent_n')
            if percent>100: raise CalculationError('Percent must not exceed 100.')
            nutrient=n('target_n',True)*n('area')/1000
            out={'pounds_n':nutrient,'pounds_product':nutrient/(percent/100)}
        elif kind == 'irrigation_runtime':
            rate=n('caught_inches')/(n('minutes')/60)
            out={'inches_per_hour':rate,'minutes':n('target_inches',True)/rate*60}
        elif kind == 'irrigation_volume': out={'us_gal':n('area')*n('depth_inches',True)*144/231}
        elif kind == 'boom': out={'us_gal_per_acre':Decimal(5940)*n('gpm')/(n('mph')*n('spacing_inches'))}
        elif kind == 'tank_split':
            total=n('area')/1000*n('carrier'); capacity=n('capacity')
            full=total//capacity
            out={'total_us_gal':total,'full_tanks':full,'partial_us_gal':total-full*capacity}
        elif kind == 'net_area':
            area=n('gross'); excluded=n('excluded',True)
            if excluded>=area: raise CalculationError('Exclusions must leave a positive treated area.')
            if inputs.get('overlap')!='none': raise CalculationError('Overlapping polygons require a geometry union, not simple subtraction.')
            out={'treated_sq_ft':area-excluded}
        elif kind == 'price':
            fraction=n('fraction',True); cost=n('cost',True)
            if fraction>=1: raise CalculationError('Fraction must be below 1.')
            out={'margin_price':cost/(1-fraction),'markup_price':cost*(1+fraction)}
        elif kind == 'residual':
            if inputs.get('composition')!='known': raise CalculationError('Residual composition is unknown.')
            if n('initial_volume',True)>n('final_volume'): raise CalculationError('Residual exceeds final volume.')
            out={'additional_product':n('concentration',True)*(n('final_volume')-n('initial_volume',True))}
        elif kind == 'seed':
            purity=n('purity'); germ=n('germination')
            if purity>1 or germ>1: raise CalculationError('Purity and germination fractions must be at most 1.')
            pls=purity*germ; target=n('target_pls',True)*n('area')/1000
            out={'pls_fraction':pls,'target_pls':target,'bulk_mass':target/pls}
        elif kind == 'economics':
            fee=n('store_fraction',True)
            if fee>=1: raise CalculationError('Store fraction must be below 1.')
            contribution=n('price',True)*(1-fee)-n('variable_cost',True)
            out={'contribution':contribution}
            if contribution>0:
                from decimal import ROUND_CEILING
                out['break_even']= (n('fixed_cost',True)/contribution).to_integral_value(rounding=ROUND_CEILING)
            else: out['break_even']=None
        else: raise CalculationError('Unsupported calculator.')
        return {'engine_version':VERSION,'kind':kind,'inputs':dict(inputs),'values':{k:None if v is None else format(v,'f') for k,v in out.items()},'status':'MATH_ONLY','label_review':'UNAVAILABLE'}
