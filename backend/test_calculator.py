"""Independent Version 3.0 arithmetic fixtures; these are not product rates."""
import unittest
from decimal import Decimal
from backend.calculator import calculate, CalculationError

class GoldenTests(unittest.TestCase):
    def test_N01_area(self):
        r=calculate('area_rate',dict(area='10000',area_unit='sq_ft',basis='1000',basis_unit='sq_ft',rate='0.5',unit='us_fl_oz'))
        self.assertEqual(Decimal(r['values']['amount']),Decimal('5'))
        self.assertEqual(r['status'],'MATH_ONLY')
        self.assertEqual(r['label_review'],'UNAVAILABLE')

    def test_N02_mass_tank(self):
        v=calculate('tank',dict(tank='60',carrier='1.5',rate='1.25',basis_sq_ft='43560',unit='oz_mass'))['values']
        self.assertEqual(Decimal(v['coverage_sq_ft']),Decimal('40000'))
        self.assertLess(abs(Decimal(v['grams'])-Decimal('32.5407749369')),Decimal('0.000000001'))

    def test_N03_mass_preserved(self):
        v=calculate('tank',dict(tank='60',carrier='1.5',rate='0.113',basis_sq_ft='1000',unit='oz_mass'))['values']
        self.assertEqual(Decimal(v['grams']),Decimal('128.139844525'))

    def test_N04_N05_calibration_changes_area_dose(self):
        a=calculate('recipe',dict(product='6',tank='55',carrier='1',unit='us_fl_oz',volume_basis='final_solution'))['values']
        b=calculate('recipe',dict(product='6',tank='55',carrier='2',unit='us_fl_oz',volume_basis='final_solution'))['values']
        self.assertEqual(a['per_us_gal'],b['per_us_gal'])
        self.assertLess(abs(Decimal(a['per_acre'])-Decimal('4.752')),Decimal('1e-30'))
        self.assertLess(abs(Decimal(b['per_acre'])-Decimal('9.504')),Decimal('1e-30'))

    def test_N06_percent(self):
        self.assertEqual(Decimal(calculate('percent_vv',dict(percent='0.25',tank='60'))['values']['us_fl_oz']),Decimal('19.2'))

    def test_N08_runtime(self):
        self.assertEqual(Decimal(calculate('irrigation_runtime',dict(caught_inches='0.4',minutes='30',target_inches='0.6'))['values']['minutes']),Decimal('45'))

    def test_N11_partial_tank(self):
        v=calculate('tank_split',dict(area='30000',carrier='1.5',capacity='20'))['values']
        self.assertEqual({k:Decimal(x) for k,x in v.items()},dict(total_us_gal=Decimal(45),full_tanks=Decimal(2),partial_us_gal=Decimal(5)))

    def test_N17_ambiguous_ounces(self):
        with self.assertRaises(CalculationError):
            calculate('tank',dict(tank='60',carrier='1.5',rate='1',basis_sq_ft='1000',unit='oz'))

    def test_N18_invalid_inputs(self):
        for area in ['0','-1','Infinity','NaN','1e6','1,000','1000000001',True]:
            with self.subTest(area=area),self.assertRaises(CalculationError):
                calculate('area_rate',dict(area=area,area_unit='sq_ft',basis='1000',basis_unit='sq_ft',rate='1',unit='g'))

    def test_N20_margin_markup(self):
        v=calculate('price',dict(cost='100',fraction='0.4'))['values']
        self.assertEqual(Decimal(v['markup_price']),Decimal(140))
        self.assertLess(abs(Decimal(v['margin_price'])-Decimal('166.6666666667')),Decimal('0.000000001'))

    def test_N38_N39_economics(self):
        for fee,expected in [('0.15','29'),('0.30','38')]:
            self.assertEqual(calculate('economics',dict(price='24.99',store_fraction=fee,variable_cost='4',fixed_cost='500'))['values']['break_even'],expected)
        self.assertIsNone(calculate('economics',dict(price='10',store_fraction='0',variable_cost='10',fixed_cost='500'))['values']['break_even'])

    def test_unknown_residual_and_starting_water_rejected(self):
        with self.assertRaises(CalculationError):
            calculate('residual',dict(composition='unknown'))
        with self.assertRaises(CalculationError):
            calculate('recipe',dict(product='6',tank='55',carrier='1',unit='us_fl_oz',volume_basis='starting_water'))

if __name__=='__main__': unittest.main()
