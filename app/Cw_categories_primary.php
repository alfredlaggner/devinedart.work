<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Cw_categories_primary extends Model
    {
        protected $connection = 'mysql2';
        protected $table = 'cw_categories_primary';
        protected $primaryKey = 'category_id'; // or null
    }
