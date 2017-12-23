<?php

namespace App;

use Illuminate\Database\Eloquent\Model;
use App\Customer_type;
class Customer extends Model
{
        protected $fillable =
            [
                'Province Code',
                'Province',
            ];

        public function type()
            {
                return $this->hasOne(Customer_type::class);
            }
    }
