<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class Cw_product_image extends Model
{
        protected $connection = 'mysql2';
        protected $table = 'cw_product_images';
        protected $primaryKey = 'product_image_id';
}
