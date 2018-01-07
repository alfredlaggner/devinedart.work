<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Cw_product_categories_primary extends Model
    {
        protected $connection = 'mysql2';
        protected $table = 'cw_product_categories_primary';
        protected $primaryKey = 'product2category_id'; // or null
    }
