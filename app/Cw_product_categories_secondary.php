<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Cw_product_categories_secondary extends Model
{
        protected $connection = 'mysql2';
        protected $table = 'cw_product_categories_secondary';
        protected $primaryKey = 'product2secondary_id';
}
