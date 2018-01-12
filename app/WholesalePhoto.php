<?php

namespace App;

use Illuminate\Database\Eloquent\Model;

class WholesalePhoto extends Model
{
        protected $connection = 'wholesale';
        protected $table = 'photos';
        protected $guarded = ['id'];

        protected $fillable = [
            'product_id',
            'name',
            'original_name',
            'order',
            'default',
            'imagetype_id',
            'special',
            'caption',
        ];

        public function products()
            {
                $this->hasOne( Product_image::class,'product_id','product_id');
            }
}
